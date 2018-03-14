import asynchttpserver, asyncdispatch
import threadpool, times, os
import rosencrantz
import routes, tcontrol, db, tdata, temperature

let mainSensorId = 1

initTControl()

proc controlLoop(): void =
  {.gcsafe.}:
    sleep(5 * 1000)
    let now = epochTime().int64
    let sensorData = getLatestSensorData(mainSensorId)
    if sensorData.len > 0:
      let last = sensorData[0]
      if last.instant > (now - 5 * 60):
        let currentTemperature = celcius(last.temperature)
        doControl(currentTemperature)

spawn controlLoop()

let server = newAsyncHttpServer()
waitFor server.serve(Port(8080), handler)
