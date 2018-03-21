import asynchttpserver, asyncdispatch
import threadpool, times, os
import rosencrantz
import routes, tcontrol

initTControl()

spawn controlLoop()

let server = newAsyncHttpServer()
var clean = false
while not clean:
  try:
    waitFor server.serve(Port(8080), handler)
    clean = true
  except:
    let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    echo "server.serve() exception ", repr(e), " with message ", msg
    