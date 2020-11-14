import rosencrantz, httpcore
import parseutils, strutils, strtabs, times, options
import asyncstuff, db, tdata, tcontrol, tutils, temperature

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

proc serializeCurrentState(sensorId: int): Future[string] {.async.} =
  proc getLatestSensorDataAux(sensorId: int): seq[SensorData] =
    getLatestSensorData(sensorId)

  let latestCurrentSensorData = await callAsync(int, sensorId,     seq[SensorData], getLatestSensorDataAux)
  let latestMainSensorData    = await callAsync(int, mainSensorId, seq[SensorData], getLatestSensorDataAux)

  result = newStringOfCap(1024)
  result.add serializeSensorData(latestCurrentSensorData)

  result.add $controlMode & "\n" # currentHvacMode
  result.add $controlState.hvac & "\n" # currentHvacStatus

  result.add $latestMainSensorData[0].temperature & "\n" # mainSensorTemperature
  result.add $currentDesiredTemperature().toCelcius() & "\n" # desiredTemperature

  let (upcomingPeriod, upcomingTime) = upcomingPeriod()
  result.add $upcomingTime.toTime().toUnix() & "\n" # upcomingTime
  result.add $upcomingPeriod.desiredTemperature.toCelcius() & "\n" # upcomingTemperature

  if override.isSome:
    result.add $options.get(override).temperature.toCelcius() & "\n" # overrideTemperature
    result.add $options.get(override).until & "\n" # overrideUntil
  else:
    result.add "0\n" # overrideTemperature
    result.add "0\n" # overrideUntil

  if forceHvac.isSome:
    result.add $options.get(forceHvac) & "\n"
  else:
    result.add "\n"

proc serializeSensorData(sensorId: int, start: int64, `end`: int64, samples: int): Future[string] {.async.} =
  let params = (sensorId, start, `end`)
  proc getSensorDataAux(params: params.type): seq[SensorData] =
    let (sensorId, start, `end`) = params
    measure("getSensorData") do:
      getSensorData(sensorId, start, `end`)

  let raw = await callAsync(params.type, params, seq[SensorData], getSensorDataAux)

  let normalized =
    if raw.len < samples and false: raw
    else: (
      let step = ((`end` - start) div samples).int;
      measure("normalize") do:
        normalize(raw, start, `end`, step)
    )
  result = measure("serialize") do:
    serializeSensorData(normalized)

proc error(msg: string): Handler =
  complete(Http500, "Server Error: " & msg, {"Content-Type": "text/plain;charset=utf-8"}.newHttpHeaders)

let gets = get[
  path("/")[
    if defined(debug):
      file("../web/src/thermopi-debug.html")
    else:
      file("../web/src/thermopi.html")
  ] ~ pathChunk("/static")[
    dir("../web/src")
  ] ~ pathChunk("/nimcache")[
    dir("../web/src/nimcache")
  ] ~ path("/api/status")[
    ok("GROOVY!")
  ] ~ path("/api/recent")[
    scope do:
      let now = epochTime().int64
      let before = now - (60 * 60 * 12) # seconds
      let body = serializeSensorDataHuman(getSensorData(before, now))
      return ok(body)
  ] ~ path("/api/sensors")[
    scope do:
      var str = ""
      for s in getSensors():
        str.add $(s.id) & "\n"
        str.add $s.name & "\n"
      return ok($str)
  ] ~ pathChunk("/api/temperature")[
    queryString(proc(s: StringTableRef): auto =
      var
        startParam = s.getOrDefault("start", "")
        endParam = s.getOrDefault("end", "")
        samplesParam = s.getOrDefault("samples", "")
      intSegment(proc(sensorId: int): auto =
        scopeAsync do:
#          try:
          let start = if startParam == "": epochTime().int64 else: startParam.parseInt
          let `end` = if endParam == "": start - (60 * 60 * 24) else: endParam.parseInt # seconds, 24 hours by default
          let samples = if samplesParam == "": 1000 else: samplesParam.parseInt
          let data = await serializeSensorData(sensorId, start, `end`, samples)
          return ok(data)
#[
          except:
            #let e = getCurrentException()
            let msg = getCurrentExceptionMsg()
            return error(msg)
]#
      )
    )
  ] ~ pathChunk("/api/current")[
    intSegment(proc (sensorId: int): auto =
      scopeAsync do:
        let data = await serializeCurrentState(sensorId)
        return ok(data)
    )
  ]
]

let posts = post[
  path("/api/temperature")[
    body(proc(str: string): auto =
      try:
        let lines = str.splitLines()
        let sensor = lines[0].parseInt()
        let temperature = lines[1].parseFloat()
        let rowid = insertSensorData(sensor, temperature)
        return ok("THXBYE - rowid " & $rowid)
      except:
        let msg = getCurrentExceptionMsg()
        echo msg
        return error(msg)

    )
  ] ~ path("/api/forceHvac")[
    body(proc(str: string): auto =
      echo "POST api/forceHvac"
      echo str
      let lines = str.splitLines()
      let newState = lines[0]
      if newState   == "On":  forceHvac = some(On)
      elif newState == "Off": forceHvac = some(Off)
      else: forceHvac = none(HvacStatus)
      ok("THXBYE " & $forceHvac)
    )
  ] ~ path("/api/override")[
    body(proc(str: string): auto =
      echo "POST api/override"
      echo str
      let lines = str.splitLines()
      let overrideTemperature = lines[0].parseFloat
      let overrideUntil = lines[1].parseInt
      if overrideUntil != 0:
        override = some(Override(
          temperature: celcius(overrideTemperature),
          until: overrideUntil
          ))
      else:
        override = none(Override)
      ok("THXBYE " & $override)
    )
  ]
]

let handler* = gets ~ posts
