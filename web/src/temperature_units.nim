import karax / jstrutils
import math

type
  TemperatureUnit* = enum
    Celcius, Fahrenheit

proc celciusToFahrenheit*(c: float): float =
  math.round(c * 1.8 + 32, 1)

proc format*(celcius: float, unit: TemperatureUnit): cstring =
  case unit
  of Celcius:
    $celcius & "C"
  of Fahrenheit:
    $celciusToFahrenheit(celcius) & "F"