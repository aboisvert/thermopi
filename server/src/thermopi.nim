import asynchttpserver, asyncdispatch
import threadpool, times, os
import rosencrantz
import routes, tcontrol, db, tdata, temperature

let mainSensorId = 1 # e.g. living room
let checkpointPeriod = 10 * 60 # period, in seconds, to checkpoint database

initTControl()

proc controlLoop(): void =
  {.gcsafe.}:
    var lastCheckpoint = 0.int64

    while true:
      sleep(5 * 1000)
      let now = epochTime().int64

      # turn HVAC system on/off based on current temperature of main sensor
      let sensorData = getLatestSensorData(mainSensorId)
      if sensorData.len > 0:
        let last = sensorData[0]
        if last.instant > (now - 5 * 60):
          let currentTemperature = celcius(last.temperature)
          doControl(currentTemperature)

      # checkpoit database
      if lastCheckpoint < now - checkpointPeriod:
        db.checkpoint()
        lastCheckpoint = now

spawn controlLoop()

let server = newAsyncHttpServer()
waitFor server.serve(Port(8080), handler)
