
type Sensor* = object
  id*: int
  name*: string

type SensorData* = object
  rowid*: int64
  instant*: int64
  sensor*: int
  temperature*: float

proc normalize*(data: seq[SensorData], from1: int64, to1: int64, step: int): seq[SensorData] =
  result = newSeqOfCap[SensorData]((to1 - from1) div step + 1)
  let sensor = data[0].sensor
  var t = from1
  var i = 0
  while t < to1:
    var sum = 0.0f
    var n = 0
    var rowid: int64 = 0
    while i < data.len and data[i].instant < t + step:
      rowid += data[i].rowid
      sum += data[i].temperature
      n += 1
      i += 1
    let point = SensorData(
      rowid: if n == 0: 0.int64 else: (rowid div n),
      instant: (t + step) div 2,
      sensor: data[0].sensor,
      temperature: if n == 0: NaN else: sum/n.float
    )
    result.add(point)
    t += step