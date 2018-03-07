#!/usr/local/bin/fish
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir=(mktemp -d -t 'chrome-remote_data_dir') \
  /Users/aboisver/thermopi/web/src/thermopi-debug.html