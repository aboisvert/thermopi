#!/bin/sh
docker image rm -f hvac_controller
docker build -t hvac_controller ./