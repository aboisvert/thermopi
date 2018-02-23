# thermopi-sensor

The sensor module is intended to run on an Arduino-like microcontroller -- the miniature ESP8266.
It sports a 32-bit RISC microprocessor, 80KB RAM, built-in Wifi, and 16 GPIO pins.

https://en.wikipedia.org/wiki/ESP8266

The sensor program is basically a simple loop,

1) Read current temperature (via 1-Wire DS18B20 digital temperature sensor)
2) Display the temperature on LCD 
3) Send the temperature reading to the server (HTTP POST)
4) Sleep for ~1 minute and repeat.
