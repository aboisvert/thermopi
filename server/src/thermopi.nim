import asynchttpserver, asyncdispatch
import threadpool, times, os
import rosencrantz
import routes, tcontrol

initTControl()

spawn controlLoop()

let server = newAsyncHttpServer()
waitFor server.serve(Port(8080), handler)
