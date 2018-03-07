#!/usr/local/bin/fish

while true
  echo "Waiting for changes ..."
  fswatch --one-event --recursive src
  #inotifywait --recursive --event modify ./ ; 
  echo "Compiling"
  nim js src/thermopi_web.nim > nim-js-output.txt ^&1

  if test $status = 0
  	cp src/thermopi.html src/thermopi-debug.html
  else
  	cp nim-js-output.txt src/thermopi-debug.html
  end

  echo "Reloading"

  # see https://github.com/Benoth/chrome-remote-reload
  darwin_amd64_chrome-remote-reload
end

