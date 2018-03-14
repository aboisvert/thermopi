import times

proc isWeekday*(dt: DateTime): bool =
  case dt.weekday
  of dMon, dTue, dWed, dThu, dFri: true
  of dSat, dSun: false

proc yesterdayAtMidnight*(dt: DateTime): DateTime =
  let yesterday = (dt.toTime() - 1.days).getLocalTime()
  initDateTime(yesterday.monthday, yesterday.month, yesterday.year, 23, 59, 59)
