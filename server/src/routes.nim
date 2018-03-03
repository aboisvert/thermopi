import rosencrantz, strutils, parseutils, db, times

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
      intSegment(proc(sensorId: int): auto =
        let now = epochTime().int64
        let before = now - (60 * 60 * 24 * 7) # seconds
        let body = serializeSensorData(getSensorData(sensorId, before, now))
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
