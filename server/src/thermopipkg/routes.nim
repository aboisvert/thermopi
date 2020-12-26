import guildenstern
import guildenstern/ctxfull
import strutils, strtabs, times, options
import db, tdata, tcontrol, tutils, temperature
from os import sleep, fileExists
import tables
import uri
import parseutils
from strutils import removePrefix

proc parseUrlEncoded*(body: string): StringTableRef {.inline.} =
  result = {:}.newStringTable
  var i = 0
  let c = body.decodeUrl
  while i < c.len - 1:
    var k, v: string
    i += c.parseUntil(k, '=', i)
    i += 1
    i += c.parseUntil(v, '&', i)
    i += 1
    result[k] = v

proc parseUrlEncodedMulti*(body: string): TableRef[string, seq[string]] {.inline.} =
  new result
  result[] = initTable[string, seq[string]]()

  var i = 0
  let c = body.decodeUrl
  while i < c.len - 1:
    var k, v: string
    i += c.parseUntil(k, '=', i)
    i += 1
    i += c.parseUntil(v, '&', i)
    i += 1
    if result.hasKey(k):
      result[k].add(v)
    else:
      result[k] = @[v]

proc serializeSensorDataHuman(data: seq[SensorData]): string =
  result = newStringOfCap(data.len * 40)
  for s in data:
    result.add $s
    result.add "\r\n"

proc serializeSensorData(data: seq[SensorData]): string =
  result = newStringOfCap(data.len * 20)
  for s in data:
    result.add $s.instant; result.add "\n"
    result.add $s.temperature; result.add "\n"

proc serializeCurrentState(sensorId: int): string =
  let latestCurrentSensorData = getLatestSensorData(sensorId)
  let latestMainSensorData    = getLatestSensorData(mainSensorId)

  result = newStringOfCap(1024)
  if latestCurrentSensorData.len == 0:
    result.add "0\n"
    result.add "0\n"
  else:
    result.add $latestCurrentSensorData[0].instant & "\n"
    result.add $latestCurrentSensorData[0].temperature & "\n"

  result.add $controlMode & "\n" # currentHvacMode
  result.add $controlState.hvac & "\n" # currentHvacStatus

  if latestMainSensorData.len > 0:
    result.add $latestMainSensorData[0].temperature & "\n" # mainSensorTemperature
  else:
    result.add "???" & "\n"

  result.add $currentDesiredTemperature().toCelcius() & "\n" # desiredTemperature

  let (upcomingPeriod, upcomingTime) = upcomingPeriod()
  result.add $upcomingTime.toTime().toUnix() & "\n" # upcomingTime
  result.add $upcomingPeriod.desiredTemperature.toCelcius() & "\n" # upcomingTemperature

  if isOverride():
    let override = getOverride()
    result.add $override.temperature.toCelcius() & "\n" # overrideTemperature
    result.add $override.until & "\n" # overrideUntil
  else:
    result.add "0\n" # overrideTemperature
    result.add "0\n" # overrideUntil

  if forceHvac.isSome:
    result.add $options.get(forceHvac) & "\n"
  else:
    result.add "\n"

proc serializeSensorData(sensorId: int, start: int64, `end`: int64, samples: int): string =
  let params = (sensorId, start, `end`)
  proc getSensorDataAux(params: params.type): seq[SensorData] =
    let (sensorId, start, `end`) = params
    measure("getSensorData") do:
      getSensorData(sensorId, start, `end`)

  let raw = getSensorDataAux(params)

  let normalized =
    if raw.len < samples and false: raw
    else: (
      let step = ((`end` - start) div samples).int;
      measure("normalize") do:
        normalize(raw, start, `end`, step)
    )
  result = measure("serialize") do:
    serializeSensorData(normalized)

# proc error(msg: string): Handler =
#   complete(Http500, "Server Error: " & msg, {"Content-Type": "text/plain;charset=utf-8"}.newHttpHeaders)

var dummyVar = 0
proc dummy(x: int): int =
  sleep(1000)
  dummyVar += 1
  result = dummyVar


proc file(path: string, ctx: HttpCtx) =
  # echo "File: " & path
  if fileExists(path):
    let f = open(path)
    defer: f.close()
    let content = f.readAll()
    ctx.reply(Http200, content)
  else:
    let msg = "Not found: " & path
    ctx.reply(Http404, msg)

proc dir(path: string, removePrefix: string, replacePrefix: string, ctx: HttpCtx) =
  var path = path
  path.removePrefix(removePrefix)
  file(replacePrefix & path, ctx)

proc ok(body: string, ctx: HttpCtx) =
  ctx.reply(Http200, body)

proc error(body: string, ctx: HttpCtx) =
  echo "Error: " & body
  ctx.reply(Http500, body)

proc lastSegment(path: string): string =
  var i = path.len - 1
  while i > 0:
    if path[i] == '/': break
    i -= 1
  result = path[i+1 .. ^1]

proc handleHttpGet(uri: Uri, ctx: HttpCtx) =
  if uri.path == "/":
    if defined(debug):
      file("../web/src/thermopi-debug.html", ctx)
    else:
      file("../web/src/thermopi.html", ctx)
  elif uri.path == "/favicon.ico":
    file("../web/src/static/favicon.ico", ctx)
  elif uri.path.startsWith("/static/"):
    dir(uri.path, "/static/", "../web/src/", ctx)
  elif uri.path.startsWith("/nimcache/"):
    dir(uri.path, "/nimcache/", "../web/src/nimcache/", ctx)
  elif uri.path.startsWith("/api/status"):
    ok("GROOVY!", ctx)
  elif uri.path.startsWith("/api/recent"):
    let now = epochTime().int64
    let before = now - (60 * 60 * 12) # seconds
    let body = serializeSensorDataHuman(getSensorData(before, now))
    ok(body, ctx)
  elif uri.path.startsWith("/test"):
    let dummy = dummy(0)
    ok($dummy, ctx)
  elif uri.path.startsWith("/api/sensors"):
    var str = ""
    let sensors = getSensors(0)
    for s in sensors:
      str.add $(s.id) & "\n"
      str.add $s.name & "\n"
    ok(str, ctx)
  elif uri.path.startsWith("/api/temperature"):
    let params = uri.query.parseUrlEncoded
    let
      startParam = params.getOrDefault("start", "")
      endParam = params.getOrDefault("end", "")
      samplesParam = params.getOrDefault("samples", "")
    let sensorId = uri.path.lastSegment().parseInt
    let start = if startParam == "": epochTime().int64 else: startParam.parseInt
    let `end` = if endParam == "": start - (60 * 60 * 24) else: endParam.parseInt # seconds, 24 hours by default
    let samples = if samplesParam == "": 1000 else: samplesParam.parseInt
    let data = serializeSensorData(sensorId, start, `end`, samples)
    ok(data, ctx)
  elif uri.path.startsWith("/api/current"):
    let sensorId = uri.path.lastSegment().parseInt
    let data = serializeCurrentState(sensorId)
    ok(data, ctx)
  else:
    error("Unknown/unexpected resource: " & uri.path, ctx)

proc handleHttpPost(uri: Uri, ctx: HttpCtx) =
  # echo "POST " & uri.path
  if uri.path.startsWith("/api/temperature"):
    let body = ctx.getBody()
    # echo "body " & body
    let lines = body.splitLines()
    let sensor = lines[0].parseInt()
    let temperature = lines[1].parseFloat()
    let rowid = insertSensorData(sensor, temperature)
    ok("THXBYE - rowid " & $rowid, ctx)

  elif uri.path.startsWith("/api/forceHvac"):
    let body = ctx.getBody()
    echo "POST api/forceHvac"
    echo body
    let lines = body.splitLines()
    let newState = lines[0]
    if newState   == "On":  forceHvac = some(On)
    elif newState == "Off": forceHvac = some(Off)
    else: forceHvac = none(HvacStatus)
    ok("THXBYE " & $forceHvac, ctx)
  elif uri.path.startsWith("/api/override"):
    let body = ctx.getBody()
    echo "POST api/override"
    echo body
    let lines = body.splitLines()
    let overrideTemperature = lines[0].parseFloat
    let overrideUntil = lines[1].parseInt
    if overrideUntil != 0:
      setOverride(Override(
        temperature: celcius(overrideTemperature),
        until: overrideUntil
        ))
    else:
      clearOverride()
    ok("THXBYE " & $getOverrideOpt(), ctx)
  else:
    error("Unknown/unexpected resource: " & uri.path, ctx)

proc handleHttpRequest*(ctx: HttpCtx, headers: StringTableRef) {.gcsafe, raises: [].} =
  {.gcsafe.}:
    try:
      # echo "thermopi handleHttpRequest"
      let uri = ctx.getUri().parseUri()
      # echo "uri: " & $uri
      if ctx.getMethod() == "GET": handleHttpGet(uri, ctx)
      elif ctx.getMethod() == "POST": handleHttpPost(uri, ctx)
      else: error("Unexpected method: " & ctx.getMethod(), ctx)
    except:
      let msg = getCurrentExceptionMsg()
      error("handleHttpRequest error: " & msg, ctx)

proc errorNotifier*(msg: string) =
  echo "thermopi error notifier: " & msg