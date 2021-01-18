#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#define ONE_WIRE_BUS 2

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

const char* ssid     = "CHANGE_ME";
const char* password = "CHANGE_ME";


const char* serverHost = "thermopi";
const int httpPort = 8080;

const int sensorId = 1;
const char* sensorHost = "thermopi-sensor-1";

const bool DEBUG = false;

const float MIN_TEMPERATURE_C = -50.0f;
const float MAX_TEMPERATURE_C = 60.0f;

void setup() {
  Serial.begin(9600);
  Serial.println("ThermoPi Sensor booting...");

  delay(100);

  sensors.begin();

  Serial.println();
  Serial.print("Local hostname:");
  Serial.print(sensorHost);
  WiFi.hostname(sensorHost);

  Serial.print("Connecting to ");
  Serial.print(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

int value = 0;

void loop() {
  char buffer[200];
  ++value;

  delay(15000);

  Serial.print("Requesting temperature... ");
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);
  Serial.println(temperature);
  if (temperature < MIN_TEMPERATURE_C || temperature > MAX_TEMPERATURE_C) {
    Serial.printf("Invalid temperature read: %.2f\n", temperature);
    return;
  }
  if (DEBUG) {
    Serial.print("Connecting to ");
    Serial.println(serverHost);
  }

  // Use WiFiClient class to create TCP connections
  WiFiClient client;
  if (!client.connect(serverHost, httpPort)) {
    Serial.printf("Connection failed to server host: %s:%d\n", serverHost, httpPort);
    return;
  }

  String url = "/api/temperature";
  if (DEBUG) {
    Serial.print("Posting data to: ");
    Serial.println(url);
  }
  char body[255];
  body[0] = '\0';

  sprintf(buffer, "%d", sensorId);
  strcat(body, buffer);
  strcat(body, "\r\n");

  sprintf(buffer, "%2.2f", temperature);
  strcat(body, buffer);
  strcat(body, "\r\n");

  sprintf(buffer, "%d", strlen(body));

  if (DEBUG) {
    Serial.println(body);
    //Serial.println(buffer);
  }

  // This will send the request to the server
  client.print(String("POST ") + url + " HTTP/1.1\r\n" +
               "Host: " + serverHost + "\r\n" +
               "Connection: close\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: " + buffer + "\r\n" +
               "\r\n");
  client.print(body);
  client.print("\r\n");
  client.print("\r\n");

  unsigned long timeout = millis();
  while (client.available() == 0) {
    if (millis() - timeout > 5000) {
      Serial.println("Timeout waiting for response!");
      client.stop();
      return;
    }
  }

  // Read all the lines of the reply from server and print them to Serial
  while (client.available()){
    String line = client.readStringUntil('\r');
    if (DEBUG) {
      Serial.print(line);
    }
  }
  client.stop();
}
