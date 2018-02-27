import rosencrantz, strutils, parseutils, db, times

let gets = get[
  path("/")[
    file("../web/src/thermopi.html")
  ] ~ pathChunk("/static")[
    dir("../web/src")
  ] ~ pathChunk("/nimcache")[
    dir("../web/nimcache")
  ] ~ path("/api/status")[
    ok("GROOVY!")
  ] ~ path("/api/recent")[
    scope do:
      let now = epochTime().int64
      let before = now - (60 * 60) # seconds
      var str = ""
      for s in getSensorData(before, now):
        str &= $s & "\r\n"
      return ok($str)
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
