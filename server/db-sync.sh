#!/bin/sh
rsync --progress -rv --rsh="ssh" thermopi:/home/pi/thermopi/server/thermopi.db* .