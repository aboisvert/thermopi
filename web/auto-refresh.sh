#!/usr/local/bin/fish

set DEFINES ""

if test -n "$LOCAL"
  set DEFINES $DEFINES -d:local
end

if test -n "$STUBS"
  set DEFINES $DEFINES -d:stubs
end

while true
  echo "Waiting for changes ..."
  fswatch --one-event --recursive src
  #inotifywait --recursive --event modify ./ ; 
  echo "Compiling"
  echo nim js $DEFINES src/thermopi_web.nim
  nim js $DEFINES src/thermopi_web.nim > nim-js-output.txt ^&1

  if test $status = 0
  	cp src/thermopi.html src/thermopi-debug.html
  else
  	cp nim-js-output.txt src/thermopi-debug.html
  end

  echo "Reloading"

  # see https://github.com/Benoth/chrome-remote-reload
  darwin_amd64_chrome-remote-reload
end

