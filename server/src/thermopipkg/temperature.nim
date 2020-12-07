import math, strformat

type
  TemperatureUnit* = enum
    Celcius,
    Fahrenheit

  Temperature* = object
    value: float
    unit: TemperatureUnit

proc celcius*(c: float): Temperature =
  Temperature(value: c, unit: Celcius)

proc fahrenheit*(f: float): Temperature =
  Temperature(value: f, unit: Fahrenheit)

proc celciusToFahrenheit*(c: float): float =
  math.round((c * 1.8) + 32, 2)

proc fahrenheitToCelcius*(f: float): float =
  math.round((f - 32) / 1.8, 2)

proc toCelcius*(t: Temperature): float =
  case t.unit
  of Celcius: t.value
  of Fahrenheit: fahrenheitToCelcius(t.value)

proc toFahrenheit*(t: Temperature): float =
  case t.unit
  of Celcius: celciusToFahrenheit(t.value)
  of Fahrenheit: t.value

proc format*(t: Temperature, unit: TemperatureUnit): string =
  case unit
  of Celcius:
    fmt"{t.toCelcius:0.1f}C"
  of Fahrenheit:
    fmt"{t.toFahrenheit:0.1f}F"

proc `<`*(t1: Temperature, t2: Temperature): bool =
  t1.toCelcius < t2.toCelcius

proc `$`*(t: Temperature): string =
  format(t, t.unit)
