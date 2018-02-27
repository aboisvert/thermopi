import db_sqlite, times, sequtils, strutils

let db = open("thermopi.db", nil, nil, nil)

type SensorData* = object
  rowid: int64
  instant: int64
  sensor: int
  temperature: float

proc insertSensorData*(instant: int64, sensor: int, temperature: float): int64 =
  db.tryInsertId(
    sql"INSERT INTO sensor_data (instant, sensor_id, temperature) VALUES (?,?,?)",
    instant, sensor, temperature)

proc insertSensorData*(sensor: int, temperature: float): int64 =
  let epoch = epochTime().int64
  insertSensorData(epoch, sensor, temperature)

proc getSensorData*(from1: int64, to1: int64): seq[SensorData] =
  let results = db.getAllRows(
    sql"SELECT * from sensor_data WHERE (instant >= ?) and (instant <= ?)",
    from1,
    to1)
  results.mapIt(SensorData(
    rowid: it[0].parseBiggestInt,
    instant: it[1].parseBiggestInt,
    sensor: it[2].parseInt,
    temperature: it[3].parseFloat))

proc `$`*(s: SensorData): string =
  "SensorData(" &
    "rowid=" & $s.rowid &
    ", instant=" & format(getLocalTime(fromSeconds(s.instant)), "d MMMM yyyy HH:mm:ss") &
    ", sensor=" & $s.sensor &
    ", temperature=" & $s.temperature & ")"