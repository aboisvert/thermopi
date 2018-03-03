import karax / [vdom, kdom, karax, karaxdsl, kajax, jstrutils, compact, jjson, jdict]
import jsffi except `&`
import random
import strutils

type
  Views = enum
    Main

  Sensor = object
    id: int
    name: cstring

# Chart.js ffi
type Chart = JsObject
proc newChart(canvas: Element, options: JsonNode): Chart {.importcpp: "new Chart(@)".}

# Moment.js ffi
type Moment = JsObject
type MomentStatic = ref object
var moment {.importc, noDecl.}: MomentStatic
proc unix(moment: MomentStatic, epoch: int): Moment {.importcpp: "#.unix(#)".}
proc format(moment: Moment, fmt: cstring): cstring {.importcpp: "#.format(#)".}

proc fromUnix(epoch: int): Moment =
  moment.unix(epoch)

const
  httpApi = cstring"http://thermopi:8080/api"
#  httpApi = cstring"http://localhost:8080/api"

let
  LF = cstring"" & "\n"

var
  currentView = Main

  currentSensor: int = 1     # currently selected sensor
  sensors: seq[Sensor] = @[] # list of sensors

  stubSensors = false # set to true when testing without a live server
  initialized = false # set to true after the first postRender()
  chart: Chart        # current temperature chart

proc createDom(data: RouterData): VNode =
  ## main renderer
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
        section(class = "graph", id = "graph"):
          canvas(id = "chart", width="400", height="400")

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

proc fakeSensorsLoaded() =
  ## generates dummy data when testing witout a live server
  var str = cstring""
  str = str & $1 & LF
  str = str & "Living Room" & LF
  sensorsLoaded(200, str)

proc updateChart(labels: openarray[cstring], temperatures: openarray[float]) =
  let ctx = document.getElementById(cstring"chart")
  let options = %*{
    "type": "line",
    "data": {
        "labels": labels,
        "datasets": [{
            "label": "Temperature",
            "data": temperatures,
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

proc temperatureLoaded(httpStatus: int, response: cstring, sensor: int) =
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

proc temperatureLoaded(sensor: int): proc (httpStatus: int, response: cstring) =
  ## returns a closure that curries `sensor` parameter
  result = proc (httpStatus: int, response: cstring) =
    temperatureLoaded(httpStatus, response, sensor)

proc fakeTemperatureLoaded() =
  ## generates dummy data when testing witout a live server
  var response = cstring""
  for i in 0 ..< 100:
    response = response & $(1520047842 + i * 10) & LF
    response = response & $(10.float + random(10).float + random(10) / 10) & LF
  temperatureLoaded(httpStatus = 200, response, sensor = 1)

proc postRender(data: RouterData) =
  if not initialized:
    if stubSensors:
      discard setTimeout(fakeSensorsLoaded, 0)
      discard setTimeout(fakeTemperatureLoaded, 0)
    else:
      ajaxGet(httpApi & "/sensors", @[], sensorsLoaded)
      ajaxGet(httpApi & "/temperature/" & $currentSensor, @[], temperatureLoaded(currentSensor))

  initialized = true

setRenderer createDom, "ROOT", postRender
