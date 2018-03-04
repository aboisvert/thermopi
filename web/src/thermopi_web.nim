import karax / [vdom, kdom, karax, karaxdsl, kajax, jstrutils, compact, jjson, jdict]
import jsffi except `&`
import random, sequtils, strutils, times
import chartjs, momentjs, url_js
import temperature_units

type
  Views = enum
    Main

  Sensor = object
    id: int
    name: cstring

  Window = enum
    T1h, T12h, T24h, T48h, T7days, T30days

const
  httpApi = cstring"http://thermopi:8080/api"
#  httpApi = cstring"http://localhost:8080/api"

let
  LF = cstring"" & "\n"

var
  currentView = Main
  currentWindow = T24h

  currentSensor: int = 1     # currently selected sensor
  sensors: seq[Sensor] = @[] # list of sensors

  currentTime: int          # seconds since epoch
  currentTemperature: float # in Celcius

  currentUnit = Fahrenheit

  stubSensors = false # set to true when testing without a live server
  initialized = false # set to true after the first postRender()

  chart: Chart # temperature chart

## Forward definitions
proc loadChartData()


proc durationInSeconds(w: Window): int = 
  case w
  of T1h:  60 * 60
  of T12h: 12 * 60 * 60
  of T24h: 24 * 60 * 60
  of T48h: 48 * 60 * 60
  of T7days: 7 * 24 * 60 * 60
  of T30days: 30 * 24 * 60 * 60

proc createDom(data: RouterData): VNode =
  ## main renderer

  let params = queryParams()

  let window = params.get("window")
  if   window == "1h":     currentWindow = T1h
  elif window == "12h":    currentWindow = T12h
  elif window == "24h":    currentWindow = T24h
  elif window == "48h":    currentWindow = T48h
  elif window == "7days":  currentWindow = T7days
  elif window == "30days": currentWindow = T30days
  echo "currentWindow: " & $currentWindow

  let beforeUnit = currentUnit
  if data.hashPart == "#celcius": currentUnit = Celcius
  elif data.hashPart == "#fahrenheit": currentUnit = Fahrenheit
  if currentUnit != beforeUnit: loadChartData()

  case currentView
  of Main:
    buildHtml(tdiv(class="thermopi-wrapper")):
      section(class = "thermopi"):

        section(class = "sensors", id = "sensors"):
          ol:
            for s in sensors:
              li(value = $s.id):
                a(href="#" & $s.name):
                  text $s.name

        section(class = "current", ):
          tdiv(id="currentTime"):
            text fromUnix(currentTime).format(cstring"dddd, h:mm a")
            if currentTime < epochTime().int - 600:
              text "  [?????]"
          tdiv(id="currentTemperature"):
            text format(currentTemperature, currentUnit)

        section(class = "window"):
          text "Window"
          text " "
          a(href="?window=1h"):
            text "1h"
          text " "
          a(href="?window=12h"):
            text "12h"
          text " "
          a(href="?window=24h"):
            text "24h"
          text " "
          a(href="?window=48h"):
            text "48h"
          text " "
          a(href="?window=7days"):
            text "7d"
          text " "
          a(href="?window=30days"):
            text "30d"

        section(class = "graph", id = "graph"):
          canvas(id = "chart", width="400", height="400")

        section(class = "units"):
          case currentUnit
          of Celcius:
            a(href="#fahrenheit"):
              text "Switch to Fahrenheit"
          of Fahrenheit:
            a(href="#celcius"):
              text "Switch to Celcius"


proc sensorsLoaded(httpStatus: int, response: cstring) =
  ## ajaxGet callback
  sensors = @[]
  let lines: seq[cstring] = response.split(LF)
  for i in 0 ..< lines.len div 2:
    let id: int = lines[i*2].parseInt
    let name: cstring = lines[i*2+1]
    let s = Sensor(id: id, name: name)
    sensors.add(s)
  redraw(kxi)

proc fakeSensorsLoad() =
  ## generates dummy data when testing witout a live server
  var str = cstring""
  str = str & $1 & LF
  str = str & "Living Room" & LF
  sensorsLoaded(200, str)

proc loadSensors() =
  if stubSensors:
    discard setTimeout(fakeSensorsLoad, 0)
  else:
    ajaxGet(httpApi & "/sensors", @[], sensorsLoaded)

proc updateChart(labels: openarray[cstring], temperatures: seq[float]) =
  var data: seq[float] = temperatures
  if currentUnit == Fahrenheit:
    data = data.mapIt(celciusToFahrenheit(it))
  let ctx = document.getElementById(cstring"chart")
  let options = %*{
    "type": "line",
    "data": {
        "labels": labels,
        "datasets": [{
            "label": "Temperature",
            "data": data,
            "backgroundColor": "rgba(255, 99, 32, 0.2)",
            "borderColor": "rgba(255,99,132,1)",
            "borderWidth": 1
        }]
    },
    "options": {
        "responsive": false
    }
  }
  chart = newChart(ctx, options)

## Current temperature

proc currentTemperatureLoaded(httpStatus: int, response: cstring, sensor: int) =
  ## ajaxGet() callback
  echo response
  let lines: seq[cstring] = response.split(LF)
  let epoch: int = lines[0].parseInt
  let temperature: float = lines[1].parseFloat
  currentTime = epoch
  currentTemperature = temperature
  redraw(kxi)

proc currentTemperatureLoaded(sensor: int): proc (httpStatus: int, response: cstring) =
  ## returns a closure that curries `sensor` parameter
  result = proc (httpStatus: int, response: cstring) =
    currentTemperatureLoaded(httpStatus, response, sensor)

proc randomCelcius(): float =
  10.float + random(10).float + random(10) / 10

proc fakeCurrentTemperatureLoad() =
  ## generates dummy data when testing witout a live server
  var response = cstring""
  let now = epochTime().int64
  response &= $now & LF
  response &= $randomCelcius() & LF
  currentTemperatureLoaded(httpStatus = 200, response, sensor = currentSensor)

proc loadCurrentTemperature() =
  if stubSensors:
    discard setTimeout(fakeCurrentTemperatureLoad, 0)
  else:
    ajaxGet(httpApi & "/current/" & $currentSensor, @[], currentTemperatureLoaded(currentSensor))

proc periodicLoadCurrentTemperature() =
  discard setTimeout(periodicLoadCurrentTemperature, 30000)
  loadCurrentTemperature()

## Chart data

proc chartDataLoaded(httpStatus: int, response: cstring, sensor: int) =
  ## ajaxGet() callback
  var labels: seq[cstring] = @[]
  var temperatures: seq[float] = @[]
  let lines: seq[cstring] = response.split(LF)
  for i in 0 ..< lines.len div 2:
    let epoch: int = lines[i*2].parseInt
    let temp: float = lines[i*2+1].parseFloat
    labels.add(fromUnix(epoch).format(cstring"dddd, h:mm a"))
    temperatures.add(temp)
  updateChart(labels, temperatures)


proc chartDataLoaded(sensor: int): proc (httpStatus: int, response: cstring) =
  ## returns a closure that curries `sensor` parameter
  result = proc (httpStatus: int, response: cstring) =
    chartDataLoaded(httpStatus, response, sensor)

proc fakeChartDataLoad() =
  ## generates dummy data when testing witout a live server
  let now = epochTime().int64
  let samplePeriod = 30
  let start = now - 100 * samplePeriod - samplePeriod
  var response = cstring""
  for i in 0 ..< 100:
    response &= $(start + i * samplePeriod) & LF
    response &= $randomCelcius() & LF
  chartDataLoaded(httpStatus = 200, response, sensor = currentSensor)

proc loadChartData() =
  if chart != nil: chart.clear()
  if stubSensors:
    discard setTimeout(fakeChartDataLoad, 0)
  else:
    let now = epochTime().int
    let start = now - durationInSeconds(currentWindow)
    let `end` = now
    var params = cstring"?"
    params &= "start=" & $start
    params &= "&end=" & $`end`
    ajaxGet(httpApi & "/temperature/" & $currentSensor & params, @[], chartDataLoaded(currentSensor))  

proc postRender(data: RouterData) =
  if not initialized:
    loadSensors()
    loadChartData()
    periodicLoadCurrentTemperature()

      

  initialized = true

setRenderer createDom, "ROOT", postRender
