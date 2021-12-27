#!/usr/bin/env fish

set DEFINES "-d:bogus"

if test -n "$STUBS"
  set DEFINES $DEFINES -d:stubs
end


set WATCHER "ls -d src/ static | entr -c -c -z -p -d true"
# on OSX
# set WATCHER fswatch --one-event --recursive src

# see https://github.com/Benoth/chrome-remote-reload
set RELOADER linux_amd64_chrome-remote-reload

# on OSX
# set RELOADER darwin_amd64_chrome-remote-reload

# don't forget to start chrome with remote debugging enabled
# https://stackoverflow.com/questions/51563287/how-to-make-chrome-always-launch-with-remote-debugging-port-flag#51593727
#
# e.g /usr/bin/google-chrome-stable --remote-debugging-port=9222

set first "true"
set debug thermopi-debug.html
open $debug
while sleep 0.1

  echo "Waiting for changes ..."
  if test "$first" = "false"
    eval $WATCHER
  end
  set first "false"

  echo "Compiling"
  #set cmd nim js $DEFINES src/thermopi_web.nim
  set cmd ./build.sh $DEFINES
  echo $cmd
  eval $cmd > nim-js-output.txt ^&1

  if test $status = 0
    cp static/thermopi.html $debug
  else
    echo "<html><body><pre>"     > $debug
    echo $cmd >> $debug
  	cat nim-js-output.txt       >> $debug
    echo "</pre></body></html>" >> $debug
    cat $debug
  end
  rm nim-js-output.txt

  echo "Reloading"

  # see https://github.com/Benoth/chrome-remote-reload
  $RELOADER
end
