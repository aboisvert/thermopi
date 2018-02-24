import rosencrantz, asynchttpserver, asyncdispatch, routes

let server = newAsyncHttpServer()

waitFor server.serve(Port(8080), handler)
