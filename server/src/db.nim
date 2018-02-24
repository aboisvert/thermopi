import db_sqlite, times

let db = open("thermopi.db", nil, nil, nil)

proc insertSensorData*(instant: int64, sensor: int, temperature: float): int64 =
  db.tryInsertId(
    sql"INSERT INTO sensor_data (instant, sensor_id, temperature) VALUES (?,?,?)", 
    instant, sensor, temperature)

proc insertSensorData*(sensor: int, temperature: float): int64 =
  let epoch = epochTime().int64
  insertSensorData(epoch, sensor, temperature)

