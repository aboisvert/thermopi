import temperature

type
  Mode* = enum
    Heating,
    Cooling

  State = object

    # externally provided
    #currentTemperature: float # celcius
    #desiredTemperature: int # celcius

    lastTransition: int64 # seconds since epoch

  DayTime* = object
    hour: int
    min: int

  Period = object
    start: DayTime
    desiredTemperature: Temperature # celcius

  Schedule* = object
    weekday: seq[Period]
    weekend: seq[Period]

let
  hystheresis = 1.0 # celcius

  quietTime = 5 * 60 # seconds between on/off transition (duty-cycle control)


  mySchedule = Schedule(
    weekday: @[
      Period(start: DayTime(hour:  6, min:  0), desiredTemperature: fahrenheit(65)),
      Period(start: DayTime(hour:  9, min:  0), desiredTemperature: fahrenheit(62)),
      Period(start: DayTime(hour: 17, min:  0), desiredTemperature: fahrenheit(65)),
      Period(start: DayTime(hour: 21, min: 30), desiredTemperature: fahrenheit(58))
    ],
    weekend: @[
      Period(start: DayTime(hour:  6, min: 30), desiredTemperature: fahrenheit(65)),
      Period(start: DayTime(hour: 21, min: 30), desiredTemperature: fahrenheit(58))
    ]
  )

