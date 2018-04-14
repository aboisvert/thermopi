import asynchttpserver, asyncdispatch
import threadpool, times, os
import rosencrantz
import routes, tcontrol

initTControl()

spawn controlLoop()

let server = newAsyncHttpServer()

try:
  asyncCheck server.serve(Port(8080), handler)
  runForever()
except:
  let e = getCurrentException()
  let msg = getCurrentExceptionMsg()
  echo "server.serve() exception ", repr(e), " with message ", msg
