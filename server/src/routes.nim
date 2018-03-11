import rosencrantz, httpcore
import parseutils, strutils, strtabs, times
import db, tdata

proc serializeSensorDataHuman(data: seq[SensorData]): string =
  result = ""
  for s in data:
    result &= $s & "\r\n"

proc serializeSensorData(data: seq[SensorData]): string =
  result = ""
  for s in data:
    result &= $s.instant & "\n"
    result &= $s.temperature & "\n"

proc error(msg: string): Handler =
  complete(Http500, "Server Error: " & msg, {"Content-Type": "text/plain;charset=utf-8"}.newHttpHeaders)

let gets = get[
  path("/")[
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
        str &= $(s.id) & "\n"
        str &= $s.name & "\n"
      return ok($str)
  ] ~ pathChunk("/api/temperature")[
      queryString(proc(s: StringTableRef): auto =
        var
          startParam = s.getOrDefault("start", "")
          endParam = s.getOrDefault("end", "")
          samplesParam = s.getOrDefault("samples", "")
        intSegment(proc(sensorId: int): auto =
          try:
            let start = if startParam == "": epochTime().int64 else: startParam.parseInt
            let `end` = if endParam == "": start - (60 * 60 * 24) else: endParam.parseInt # seconds, 24 hours by default
            let samples = if samplesParam == "": 1000 else: samplesParam.parseInt

            let raw = getSensorData(sensorId, start, `end`)
            let normalized =
              if raw.len < samples: raw
              else: (
                let step = ((`end` - start) div samples).int;
                normalize(raw, start, `end`, step)
              )
            let body = serializeSensorData(normalized)
            return ok(body)
          except:
            let e = getCurrentException()
            let msg = getCurrentExceptionMsg()
            return error(msg)

        )
      )
  ] ~ pathChunk("/api/current")[
      intSegment(proc(sensorId: int): auto =
        let body = serializeSensorData(getLatestSensorData(sensorId))
        return ok(body)
      )
  ]
]

let posts = post [
  path("/api/temperature")[
    body(proc(str: string): auto =
      echo "POST api/temperature"
      echo str

      let lines = str.splitLines()
      let sensor = lines[0].parseInt()
      echo "sensor: " & $sensor
      let temperature = lines[1].parseFloat()
      echo "temperature: " & $temperature
      let rowid = insertSensorData(sensor, temperature)
      echo "rowid: " & $rowid
      ok("THXBYE - rowid " & $rowid)
    )
  ]
]

let handler* = gets ~ posts
