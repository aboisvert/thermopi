# Package

version       = "0.1.0"
author        = "Alex Boisvert"
description   = "HVAC controller (ESP32)"
license       = "Apache-2.0"
srcDir        = "main"

bin           = @["hvac_controller"]

# Dependencies
requires "nim >= 1.4.2"
#requires "https://github.com/elcritch/nesper#devel"
requires "https://github.com/aboisvert/nesper#fix_createTimer"
