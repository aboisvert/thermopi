import db_sqlite, times, sequtils, strutils

let db = open("thermopi.db", nil, nil, nil)

type Sensor* = object
  id*: int
  name*: string

proc getSensors*(): seq[Sensor] =
  let results = db.getAllRows(sql"SELECT * FROM sensors")
  results.mapIt(Sensor(
    id: it[0].parseInt,
    name: it[1]))

type SensorData* = object
  rowid*: int64
  instant*: int64
  sensor*: int
  temperature*: float

proc insertSensorData*(instant: int64, sensor: int, temperature: float): int64 =
  db.tryInsertId(
    sql"INSERT INTO sensor_data (instant, sensor_id, temperature) VALUES (?,?,?)",
    instant, sensor, temperature)

proc insertSensorData*(sensor: int, temperature: float): int64 =
  let epoch = epochTime().int64
  insertSensorData(epoch, sensor, temperature)

proc rowsToSensorData(rows: seq[seq[string]]): seq[SensorData] =
  rows.mapIt(SensorData(
    rowid: it[0].parseBiggestInt,
    instant: it[1].parseBiggestInt,
    sensor: it[2].parseInt,
    temperature: it[3].parseFloat))

proc getSensorData*(from1: int64, to1: int64): seq[SensorData] =
  let rows = db.getAllRows(
    sql"SELECT * from sensor_data WHERE (instant >= ?) and (instant <= ?)",
    from1,
    to1)
  rowsToSensorData(rows)

proc getSensorData*(sensor: int, from1: int64, to1: int64): seq[SensorData] =
  let rows = db.getAllRows(
    sql"SELECT * from sensor_data WHERE (sensor_id = ?) and (instant >= ?) and (instant <= ?)",
    sensor,
    from1,
    to1)
  rowsToSensorData(rows)

proc `$`*(s: SensorData): string =
  "SensorData(" &
    "rowid=" & $s.rowid &
    ", instant=" & format(getLocalTime(fromSeconds(s.instant)), "d MMMM yyyy HH:mm:ss") &
    ", sensor=" & $s.sensor &
    ", temperature=" & $s.temperature & ")"

