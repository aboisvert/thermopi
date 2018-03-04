import db
import rosencrantz
import parseutils, strutils, strtabs, times

proc serializeSensorDataHuman(data: seq[SensorData]): string =
  result = ""
  for s in data:
    result &= $s & "\r\n"

proc serializeSensorData(data: seq[SensorData]): string =
  result = ""
  for s in data:
    result &= $s.instant & "\n"
    result &= $s.temperature & "\n"

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
          startParam = s["start"]
          endParam = s["end"]
        intSegment(proc(sensorId: int): auto =
          let start = if startParam == nil: epochTime().int64 else: startParam.parseInt
          let `end` = if endParam == nil: start - (60 * 60 * 24) else: endParam.parseInt # seconds, 24 hours by default
          let body = serializeSensorData(getSensorData(sensorId, start, `end`))
          return ok(body)
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
