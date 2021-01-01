#!/usr/bin/env fish
if test -n "$USB"
  set USB_DEVICE "--device=/dev/ttyUSB0"
end

docker run --rm -v $PWD:/project $USB_DEVICE -w /project -it hvac_controller /usr/bin/fish
