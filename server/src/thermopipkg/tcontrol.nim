import options, os, times, strutils
import temperature, datetime
import db, tdata, options

when defined(controlPi):
  {.passL: "-lwiringPi".}
  import wiringPi

type
  ControlMode* = enum NoControl, Heating, Cooling

  HvacStatus* = enum Off, On

  ControlState* = object
    hvac*: HvacStatus
    lastTransition*: int64 # seconds since epoch

  DayTime* = object
    hour*: int
    min*: int

  Period* = object
    start*: DayTime
    desiredTemperature*: Temperature # celcius

  Schedule* = object
    weekday: seq[Period]
    weekend: seq[Period]

  Override* = object
    temperature*: Temperature
    until*: int64 # seconds since epoch

# Forward declarations
proc defaultControlMode(): ControlMode
proc calcDesiredTemperature(schedule: Schedule, dt: DateTime): Temperature
proc saveOverride*()

let
  hysteresis_above = 1.0 # celcius
  hysteresis_below = 0.5 # celcius

  quietTime = 5 * 60 # seconds between on/off transition (duty-cycle control)

  mySchedule = Schedule(
    weekday: @[
      Period(start: DayTime(hour:  5, min: 15), desiredTemperature: fahrenheit(68)),
      Period(start: DayTime(hour:  9, min:  0), desiredTemperature: fahrenheit(64)),
      Period(start: DayTime(hour: 17, min:  0), desiredTemperature: fahrenheit(65)),
      Period(start: DayTime(hour: 21, min: 30), desiredTemperature: fahrenheit(58))
    ],
    weekend: @[
      Period(start: DayTime(hour:  6, min: 30), desiredTemperature: fahrenheit(68)),
      Period(start: DayTime(hour: 21, min: 30), desiredTemperature: fahrenheit(58))
    ]
  )

when defined(controlPi):
  let
    heatingPin: cint = 0
    coolingPin: cint = 1

var
  controlState* = ControlState(hvac: Off, lastTransition: 0)
  controlMode* = defaultControlMode()
  override: Option[Override] = none(Override)
  forceHvac*: Option[HvacStatus] = none(HvacStatus)
  lastPrintedTemperature = 0.int64

proc `$`*(o: Override): string =
  "Override(" &
    "temperature: " & $o.temperature &
    ", until: " & format(fromUnix(o.until).local(), "d MMMM yyyy HH:mm:ss") &
    ")"

const OVERRIDE_FILENAME {.strdefine.} = "override.thermopi"

proc isOverride*: bool = override.isSome
proc getOverride*: Override = override.get
proc getOverrideOpt*: Option[Override] = override

proc setOverride*(newValue: Override) =
  override = some(newValue)
  saveOverride()

proc clearOverride*() =
  override = none[Override]()
  saveOverride()

proc saveOverride*() =
  echo "Save override: ", override
  let f = open(OVERRIDE_FILENAME, FileMode.fmWrite)
  defer: f.close()
  if override.isNone:
    f.write("# none")
  else:
    let o = override.get
    f.write o.temperature.format(Celcius), " # ", o.temperature.format(Fahrenheit), "\n"
    f.write o.until, " # ", format(fromUnix(o.until).local(), "d MMMM yyyy HH:mm:ss")

proc loadOverride*(): Option[Override] =
  if not fileExists(OVERRIDE_FILENAME): return none(Override)
  let f = open(OVERRIDE_FILENAME, FileMode.fmRead)
  defer: f.close()

  let temperature = block:
    let l1 = f.readLine()
    if l1.contains("none"): return none(Override)
    celcius(parseFloat(l1.split('#')[0].split('C')[0]))

  let until = block:
    let l2 = f.readLine()
    parseBiggestInt(l2.split('#')[0].strip())

  result = some(Override(temperature: temperature, until: until))
  echo "Loaded override: ", result

# General logic:
# - if heating mode and current temperature < desired, turn on heating
# - if cooling mode and current temperature > desired turn on AC
proc updateState(currentState: ControlState, currentMode: ControlMode, currentTime: int64,
  currentTemperature: Temperature, desiredTemperature: Temperature): ControlState =
  result = currentState

  var actualState = Off
  when defined(controlPi):
    case currentMode
    of NoControl:
      actualState = Off
    of Heating:
      actualState = if digitalRead(heatingPin) == 0: On else: Off
    of Cooling:
      actualState = if digitalRead(coolingPin) == 0: On else: Off
  else:
    actualState = Off


  case currentMode
  of NoControl:
    result.hvac = Off

  of Heating:
    if currentTemperature.toCelcius < (desiredTemperature.toCelcius - hysteresis_below):
      #echo $currentTemperature.toCelcius
      #echo $desiredTemperature.toCelcius
      #echo $hysteresis
      #echo $(desiredTemperature.toCelcius - hysteresis)
      if actualState == Off:
        if currentTime > (currentState.lastTransition + quietTime):
          result.lastTransition = currentTime
          result.hvac = On
    elif currentTemperature.toCelcius > (desiredTemperature.toCelcius + hysteresis_above):
      if currentState.hvac == On or actualState == On:  # no quietTime to turn off
        result.lastTransition = currentTime
        result.hvac = Off

  of Cooling:
    if currentTemperature.toCelcius > (desiredTemperature.toCelcius + hysteresis_below):
      if actualState == Off:
        if currentTime > (currentState.lastTransition + quietTime):
          result.lastTransition = currentTime
          result.hvac = On
    elif currentTemperature.toCelcius < (desiredTemperature.toCelcius - hysteresis_above):
      if currentState.hvac == On or actualState == On:  # no quietTime to turn off
        result.lastTransition = currentTime
        result.hvac = Off

  if forceHvac.isSome():
    result.hvac = forceHvac.get()

proc initTControl*() =
  override = loadOverride()
  when defined(controlPi):
    if (wiringPiSetup() == -1):
      raise newException(OSError, "wiringPiSetup failed")

    for pin in [heatingPin, coolingPin]:
      pin.pinMode(OUTPUT)
      pin.digitalWrite(1) # relay is active low

proc controlHvac(c: HvacStatus) =
  echo "Control HVAC: " & $controlMode & " -> " & $c

  case controlMode
  of NoControl:
    echo "No control - HvacStatus: " & $c
  of Heating:
    echo "Heating - HvacStatus: " & $c
    when defined(controlPi):
      if c == On:  digitalWrite(heatingPin, 0) # Relay is active low
      if c == Off: digitalWrite(heatingPin, 1)
      digitalWrite(coolingPin, 1) # Force cooling off (relay is active low)
  of Cooling:
    echo "Cooling - HvacStatus: " & $c
    when defined(controlPi):
      if c == On:  digitalWrite(coolingPin, 0)
      if c == Off: digitalWrite(coolingPin, 1)
      digitalWrite(heatingPin, 1) # Force heating off (relay is active low)

proc currentDesiredTemperature*(): Temperature =
  if isOverride():
    let override = getOverride()
    override.temperature
  else:
    calcDesiredTemperature(mySchedule, getTime().local())


proc doControl*(currentTemperature: Temperature) =
  let currentTime = epochTime().int64

  let desiredTemperature = currentDesiredTemperature()
  if lastPrintedTemperature < currentTime - 60:
    lastPrintedTemperature = currentTime
    echo "current: " & currentTemperature.format(Fahrenheit) &
      " desired: " & desiredTemperature.format(Fahrenheit) &
      " +/- (" & $(hysteresis_above * C_TO_F_FACTOR) & ", " & $(hysteresis_below * C_TO_F_FACTOR) & ")"

  let oldState = controlState

  controlState = updateState(
    controlState, controlMode, currentTime,
    currentTemperature, desiredTemperature)

  if controlMode != NoControl and oldState != controlState:
    controlHvac(controlState.hvac)


proc findPeriod(periods: seq[Period], dt: DateTime): Option[Period] =
  var i = periods.len - 1
  while i >= 0:
    let p = periods[i]
    let h = p.start.hour
    let m = p.start.min
    if (h < dt.hour) or (h == dt.hour and m <= dt.minute):
      return some(p)
    i -= 1
  return none(Period)


proc periodAt(schedule: Schedule, dt: DateTime): Period =
  let periods = if dt.isWeekday(): schedule.weekday else: schedule.weekend
  let period = findPeriod(periods, dt)
  if period.isSome():
    return period.get()
  else:
    let yesterday = yesterdayAtMidnight(dt)
    let periods = if yesterday.isWeekday(): schedule.weekday else: schedule.weekend
    return periods[^1]

proc calcDesiredTemperature(schedule: Schedule, dt: DateTime): Temperature =
  periodAt(schedule, dt).desiredTemperature

proc upcomingPeriod(periods: seq[Period], dt: DateTime): Option[Period] =
  result = none(Period)
  var i = periods.len - 1
  while i >= 0:
    let p = periods[i]
    let h = p.start.hour
    let m = p.start.min
    if (h < dt.hour) or (h == dt.hour and m <= dt.minute):
      return result
    result = some(p)
    i -= 1
  return result

proc upcomingPeriod(schedule: Schedule, dt: DateTime): (Period, DateTime) =
  let periods = if dt.isWeekday(): schedule.weekday else: schedule.weekend
  let period = upcomingPeriod(periods, dt)
  if period.isSome():
    let period = period.get()
    (period, dt.at(period.start.hour, period.start.min, 0))
  else:
    let tomorrow = tomorrowAtMidnight(dt)
    let periods = if tomorrow.isWeekday(): schedule.weekday else: schedule.weekend
    let period = periods[0]
    (period, tomorrow.at(period.start.hour, period.start.min, 0))

proc upcomingPeriod*(): (Period, DateTime) =
  upcomingPeriod(mySchedule, getTime().local())

proc isSummer(): bool =
  let t = getTime().local()
  case t.month
  of mJun, mJul, mAug, mSep: true
  else: false

proc isWinter(): bool =
  let t = getTime().local()
  case t.month
  of mOct, mNov, mDec, mJan, mFeb, mMar, mApr, mMay: true
  else: false

proc defaultControlMode(): ControlMode =
  if isSummer(): Cooling
  elif isWinter(): Heating
  else: NoControl


## Control loop

let mainSensorId* = 1 # e.g. living room
let checkpointPeriod = 10 * 60 # period, in seconds, to checkpoint database

proc controlLoop*(): void =
  {.gcsafe.}:
    var lastCheckpoint = 0.int64

    while true:
      try:
        sleep(5 * 1000)
        let now = epochTime().int64

        # check if override has expired
        if isOverride():
          let override = getOverride()
          if override.until <= now:
            echo "Override has expired: " & $override
            clearOverride()

        if forceHvac.isSome:
          echo "HVAC is forced " & $forceHvac.get
          controlHvac(forceHvac.get)
        else:
          # turn HVAC system on/off based on current temperature of main sensor
          let sensorData = getLatestSensorData(mainSensorId)
          if sensorData.len > 0:
            let last = sensorData[0]
            if last.instant > (now - (5 * 60)):
              let currentTemperature = celcius(last.temperature)
              doControl(currentTemperature)
            else:
              echo "No reading from main sensor since " & $last.instant & "; turning HVAC off."
              controlHvac(Off)
          else:
            echo "No latest main sensor data ?!? "
            controlHvac(Off)

        # checkpoit database
        if lastCheckpoint < now - checkpointPeriod:
          db.checkpoint()
          lastCheckpoint = now
      except:
        let e = getCurrentException()
        let msg = getCurrentExceptionMsg()
        echo "controlLoop() exception ", repr(e), " with message ", msg
