import karax / jstrutils
import math, times
import temperature

type
  TemperatureUnit* = enum
    Celcius, Fahrenheit

const
  C_TO_F_FACTOR* = 1.8
  C_TO_F_OFFSET* = 32

proc celciusToFahrenheit*(c: float): float =
  math.round(c * C_TO_F_FACTOR + C_TO_F_OFFSET, 2)

proc fahrenheitToCelcius*(f: float): float =
  math.round((f - C_TO_F_OFFSET) / C_TO_F_FACTOR, 2)

proc format*(celcius: float, unit: TemperatureUnit): cstring =
  case unit
  of Celcius:
    $math.round(celcius, 1) & "C"
  of Fahrenheit:
    $math.round(celciusToFahrenheit(celcius), 1) & "F"

proc at*(dt: DateTime, hour: int, minute: int, second: int): DateTime =
  initDateTime(dt.monthday, dt.month, dt.year, hour, minute, second)
