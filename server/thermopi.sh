#!/bin/sh
killall thermopi
sleep 1
nohup ./thermopi > /home/pi/thermopi/server/thermopi.log 2>&1 &