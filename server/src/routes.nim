import rosencrantz, strutils, parseutils, db

let gets = get[
  path("/api/status")[
    ok("GROOVY!")
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
