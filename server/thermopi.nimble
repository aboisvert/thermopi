# Package

version       = "0.1.0"
author        = "Alex Boisvert"
description   = "A Nest-like intelligent thermostat implementation for the Raspberry Pi"
license       = "BSD"

srcDir        = "src"
bin           = @["thermopi"]

# Dependencies

requires "nim >= 1.0.0"
requires "rosencrantz 0.4.1"


task test, "Runs the test suite":
  exec "nim c -r tests/tester"
