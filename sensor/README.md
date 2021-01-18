# thermopi-sensor

The sensor module is intended to run on an Arduino-like microcontroller -- the miniature ESP8266 NodeMCU v2/v3 variants.

It sports a 32-bit RISC microprocessor, 80KB RAM, built-in Wifi, and 16 GPIO pins.

https://en.wikipedia.org/wiki/ESP8266
https://en.wikipedia.org/wiki/NodeMCU

The sensor program is basically a simple loop,

1) Read current temperature (via 1-Wire DS18B20 digital temperature sensor)
2) Display the temperature on LCD (not implemented currently)
3) Send the temperature reading to the server (HTTP POST)
4) Sleep for ~1 minute and repeat.


## Driver for CH340G-based NodeCMU 340G (Arduino clone)

If you are working on a Mac, this may be helpful:
https://github.com/adrianmihalko/ch340g-ch34g-ch34x-mac-os-x-driver

## Prerequisite

Install PlatformIO to build the project, and to upload to your device.

https://docs.platformio.org/en/latest/core/installation.html
