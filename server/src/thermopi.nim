import std/threadpool

from std/strutils   import parseInt
from std/os         import getEnv, existsEnv
from std/osproc     import countProcessors

import guildenstern, guildenstern/[ctxfull]

import thermopipkg/[routes, tcontrol]

let port = getEnv("PORT", "8080").parseInt

let threadCount = block:
  var threads = countProcessors() + 2
  if existsEnv("THREADS"):
    threads = getEnv("THREADS").parseInt
  threads

echo "Thermopi starting on port ", port, " with ", threadCount, " threads."

initTControl()
spawn controlLoop()

var server = new GuildenServer
server.initFullCtx(onRequestCallback = handleHttpRequest, port = port)
server.serve(threadCount = threadCount, loglevel = ERROR)