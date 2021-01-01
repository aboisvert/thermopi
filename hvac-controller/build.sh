#!/usr/bin/env fish

function posix-source
  for i in (cat $argv)
    set arr (string split -m1 = $i)
    set -gx $arr[1] $arr[2]
  end
end

function sample_secrets
echo '
WIFI_SSID="Example"
WIFI_PASSWORD="MySecurePassword"
'
end

if test -e ./.secrets.env
  posix-source ./.secrets.env
else
  echo "Please create '.secrets.env' file with environment variables"
  sample_secrets
  exit 1
end

nimble build
make

