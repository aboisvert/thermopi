import karax / jstrutils

type
  TemperatureUnit* = enum
    Celcius, Fahrenheit

proc celciusToFahrenheit*(c: float): float =
  c * 1.8 + 32

proc format*(celcius: float, unit: TemperatureUnit): cstring =
  case unit
  of Celcius:
    $celcius & "C"
  of Fahrenheit:
    $celciusToFahrenheit(celcius) & "F"