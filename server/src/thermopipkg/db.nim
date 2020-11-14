import db_sqlite, times, sequtils, strutils
import tdata

let db = open("thermopi.db", "", "", "")

proc getSensors*(): seq[Sensor] =
  let results = db.getAllRows(sql"SELECT * FROM sensors")
  results.mapIt(Sensor(
    id: it[0].parseInt,
    name: it[1]))

proc insertSensorData*(instant: int64, sensor: int, temperature: float): int64 =
  db.exec(sql"BEGIN")
  try:
    let id = db.tryInsertId(
      sql"INSERT INTO sensor_data (instant, sensor_id, temperature) VALUES (?,?,?)",
      instant, sensor, temperature)
    db.exec(sql"COMMIT")
    return id
  except:
    db.exec(sql"ROLLBACK")
    let e = getCurrentException()
    raise e

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

proc getLatestSensorData*(sensor: int): seq[SensorData] =
  let rows = db.getAllRows(
    sql"SELECT * from sensor_data WHERE (sensor_id = ?) ORDER BY instant DESC LIMIT 1", sensor)
  rowsToSensorData(rows)

proc `$`*(s: SensorData): string =
  "SensorData(" &
    "rowid=" & $s.rowid &
    ", instant=" & format(fromUnix(s.instant).local(), "d MMMM yyyy HH:mm:ss") &
    ", sensor=" & $s.sensor &
    ", temperature=" & $s.temperature & ")"

proc checkpoint*() =
  db.exec(sql"PRAGMA wal_checkpoint")



