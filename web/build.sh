#!/usr/bin/env fish

# Usage:
#
# ./build.sh -d:host=localhost -d:port=8080
#
# Optional:
#   -d:host=thermopi  (default)
#   -d:port=8080      (default)
#   -d:stubs          (turns on stub apis, for server-less development)

mkdir nimcache/
nimble build $argv
and mv thermopi_web.js nimcache/