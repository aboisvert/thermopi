mode = ScriptMode.Verbose

# Package

version       = "0.1.0"
author        = "Alex Boisvert"
description   = "Web interface (single-page app) for ThermoPi"
license       = "BSD"
srcDir        = "src"
backend       = "js"

bin           = @["thermopi_web"]

# Dependencies

requires "nim >= 0.17.2", "karax .2.0"

