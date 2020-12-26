import karax / [kdom, jjson]
import jsffi

##
## Minimal untyped Chart.js FFI
##
## (should work with Chart.js v2.x -- tested with Charts.js 2.7.2)
##
## See http://www.chartjs.org/

type Chart* = JsObject

type Context2D* = JsObject

proc newChart*(canvas: Context2D, options: JsonNode): Chart {.importcpp: "new Chart(@)".}

proc getContext2D*(canvas: Element): Context2D =
  {.emit: """`result` = `canvas`.getContext('2d');"""}

proc clearCanvas*(canvas: Element) =
  {.emit: """
    var context = `canvas`.getContext('2d');
    context.clearRect(0, 0, `canvas`.width, `canvas`.height);
  """}

##
## Examples
##

{.push hint[XDeclaredButNotUsed]: off.}

## Assumes you have:
##
##   <script type="text/javascript" src="Chart.min.js" />
##
## and
##
##   <canvas id="myChart" width="400" height="400"></canvas>
##

proc temperatureChartExample(labels: seq[cstring], temperatures: seq[float]) =
  let canvas = document.getElementById(cstring"myChart")
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
  discard newChart(canvas.getContext2D(), options)

{.pop.}
