
import guildenstern
import guildenstern/ctxfull
import guildenstern/ctxheader
import thermopipkg/routes
import thermopipkg/tcontrol
import threadpool

const port {.intdefine.} = 8080

echo "Thermopi starting on port ", port

initTControl()
spawn controlLoop()

var server = new GuildenServer
server.initFullCtx(handleHttpRequest, port)
server.registerErrornotifier(errorNotifier)
server.serve(multithreaded = true)