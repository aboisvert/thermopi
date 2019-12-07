#!/bin/sh -e
nimble c -d:controlPi -d:release src/thermopi.nim
mv src/thermopi .
