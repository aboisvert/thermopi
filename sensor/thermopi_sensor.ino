#include <ESP8266WiFi.h>
#include <OneWire.h> 
#include <DallasTemperature.h>

#define ONE_WIRE_BUS 2 

OneWire oneWire(ONE_WIRE_BUS); 
DallasTemperature sensors(&oneWire);

const char* ssid     = "CHANGE-ME";
const char* password = "CHANGE-ME";

const char* host = "thermopi";
const int httpPort = 8080;

const int sensorId = 3;


void setup() {
  Serial.begin(115200); 

  delay(100);

  sensors.begin(); 

  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");  
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

int value = 0;

void loop() {
  delay(5000);
  ++value;


  Serial.print(" Requesting temperatures..."); 
  sensors.requestTemperatures(); 
  float temperature = sensors.getTempCByIndex(0);
  Serial.print(temperature);

  Serial.print("Connecting to ");
  Serial.println(host);
  
  // Use WiFiClient class to create TCP connections
  WiFiClient client;
  if (!client.connect(host, httpPort)) {
    Serial.println("connection failed");
    return;
  }
  
  String url = "/api/temperature";
  Serial.print("Requesting URL: ");
  Serial.println(url);

  char body[255];
  char buffer[50];
  body[0] = '\0';

  sprintf(buffer, "%d", sensorId);
  strcat(body, buffer);
  strcat(body, "\r\n");

  sprintf(buffer, "%2.2f", temperature);
  strcat(body, buffer);
  strcat(body, "\r\n");

  sprintf(buffer, "%d", strlen(body));

  Serial.println(body);
  Serial.println(buffer);
  
  // This will send the request to the server
  client.print(String("POST ") + url + " HTTP/1.1\r\n" +
               "Host: " + host + "\r\n" + 
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
      Serial.println(">>> Client Timeout !");
      client.stop();
      return;
    }
  }
  
  // Read all the lines of the reply from server and print them to Serial
  while(client.available()){
    String line = client.readStringUntil('\r');
    Serial.print(line);
  }
  client.stop();
  delay(5000);
}


