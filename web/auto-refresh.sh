#!/usr/local/bin/fish

set DEFINES ""

if test -n "$LOCAL"
  set DEFINES $DEFINES -d:local
end

if test -n "$STUBS"
  set DEFINES $DEFINES -d:stubs
end

set first "true"

while true
  echo "Waiting for changes ..."
  if test "$first" = "false"
    fswatch --one-event --recursive src
  end
  set first "false"
  #inotifywait --recursive --event modify ./ ; 
  echo "Compiling"
  echo nim js $DEFINES src/thermopi_web.nim
  nim js $DEFINES src/thermopi_web.nim > nim-js-output.txt ^&1

  set debug src/thermopi-debug.html
  if test $status = 0
  	cp src/thermopi.html $debug
  else
    echo "<html><body><pre>"     > $debug
  	cat nim-js-output.txt       >> $debug
    echo "</pre></body></html>" >> $debug
    cat $debug
  end

  echo "Reloading"

  # see https://github.com/Benoth/chrome-remote-reload
  darwin_amd64_chrome-remote-reload
end

