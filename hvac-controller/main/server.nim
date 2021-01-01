
import
  std/asynchttpserver,
  std/asyncdispatch,
  std/strutils,
  nesper/esp/esp_log,
  nesper/timers,
  nesper/gpios,
  hvac_utils

type
  HvacStatus* = enum Off, On

  Server* = object
    count: int64
    lastUpdate: Millis
    currentHvacState: HvacStatus
    desiredHvacState: HvacStatus

const ALIVE_TIMEOUT* = Millis(60 * 1000)

template importServer(this: ptr Server) =
  template count: var int64 {.used.}       = this.count
  template lastUpdate: var Millis {.used.}       = this.lastUpdate
  template currentHvacState: var HvacStatus {.used.} = this.currentHvacState
  template desiredHvacState: var HvacStatus {.used.} = this.desiredHvacState

proc updateHvacState*(this: ptr Server) =
  importServer this

  let now = millis()
  let secondsSinceLastUpdate = (now - lastUpdate) div 1000

  logi TAG, "updateHvacState() currentHvacState=%s desiredHvacState=%s secondsSinceLastUpdate=%s",
    $currentHvacState,
    $desiredHvacState,
    $secondsSinceLastUpdate

  if desiredHvacState == On and lastUpdate + ALIVE_TIMEOUT < now:
    logi TAG, "turning HVAC off due to timeout ..."
    desiredHvacState = Off

  if currentHvacState != desiredHvacState:
    if desiredHvacState == On:
      logi TAG, "Turning HVAC on"
      setLevel(GPIO_NUM_2, 1)
    else:
      logi TAG, "Turning HVAC off"
      setLevel(GPIO_NUM_2, 0)
    currentHvacState = desiredHvacState

proc handleHttpRequest(this: ptr Server): (proc (req: Request): Future[void] {.gcsafe.}) =
  importServer(this)
  result = proc (req: Request): Future[void] {.async.} =
    {.gcsafe.}:
      inc count
      echo "req #", count
      var response = ""
      var httpCode = Http200
      if req.body.contains("on"):
        response = "turn on"
        desiredHvacState = On
        lastUpdate = millis()
        this.updateHvacState()
      elif req.body.contains("off"):
        response = "turn off"
        desiredHvacState = Off
        lastUpdate = millis()
        this.updateHvacState()
      else:
        echo "bad request:\n" & req.body & "\n"
        response = "bad request"
        httpCode = Http400
      echo "response: " & response
      await req.respond(httpCode, response & "\n")
      discard

proc start*(this: ptr Server, port: int) =
  importServer(this)

  echo "Starting http server on port " & $port
  lastUpdate = millis()
  currentHvacState = Off
  desiredHvacState = Off
  this.updateHvacState()

  # LED + RelaySwitch
  configure({GPIO_NUM_2}, GPIO_MODE_OUTPUT)
  setLevel(GPIO_NUM_2, 0)

  var httpServer = newAsyncHttpServer()
  waitFor httpServer.serve(Port(port), this.handleHttpRequest())


when isMainModule:
  proc main() =
    var server: Server
    addr(server).start(port = 8080)
    runForever()

  main()