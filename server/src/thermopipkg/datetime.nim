import times

proc isWeekday*(dt: DateTime): bool =
  case dt.weekday
  of dMon, dTue, dWed, dThu, dFri: true
  of dSat, dSun: false

proc at*(dt: DateTime, hour: int, minute: int, second: int): DateTime =
  initDateTime(dt.monthday, dt.month, dt.year, hour, minute, second)

proc yesterdayAtMidnight*(dt: DateTime): DateTime =
  let yesterday = (dt.toTime() - 1.days).local()
  yesterday.at(23, 59, 59)

proc tomorrowAtMidnight*(dt: DateTime): DateTime =
  let tomorrow = (dt.toTime() + 1.days).local()
  tomorrow.at(0, 0, 1)

