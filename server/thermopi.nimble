# Package

version       = "0.1.0"
author        = "Alex Boisvert"
description   = "A Nest-like intelligent thermostat implementation for the Raspberry Pi"
license       = "BSD"

srcDir        = "src"
bin           = @["thermopi"]

# Dependencies

requires "nim 0.17.2"
requires "rosencrantz 0.3.2"




task test, "Runs the test suite":
  exec "nim c -r tests/tester"
