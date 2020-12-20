# Package

version       = "0.1.0"
author        = "Alex Boisvert"
description   = "A Nest-like intelligent thermostat implementation for the Raspberry Pi"
license       = "BSD"

srcDir        = "src"
bin           = @["thermopi"]

# Dependencies

requires "nim >= 1.4.0"
requires "https://github.com/aboisvert/GuildenStern#8e7c08c"

task test, "Runs the test suite":
  exec "nim c -r tests/tester"
