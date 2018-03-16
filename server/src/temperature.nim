import math

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
  math.round(c * 1.8 + 32, 1)

proc fahrenheitToCelcius*(f: float): float =
  math.round(f - 32 / 1.8, 1)

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
    $t.toCelcius & "C"
  of Fahrenheit:
    $t.toFahrenheit & "F"

proc `<`*(t1: Temperature, t2: Temperature): bool =
  t1.toCelcius < t2.toCelcius

proc `$`*(t: Temperature): string =
  case t.unit
  of Celcius: $t.value & "C"
  of Fahrenheit: $t.value & "F"
