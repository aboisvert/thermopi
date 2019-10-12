#!/bin/sh -e
nimble c -d:controlPi src/thermopi.nim
mv src/thermopi .
