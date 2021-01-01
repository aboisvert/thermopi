import nesper/consts

const TAG*: cstring = "hvac-controller"

proc `div`*(m: Millis, denominator: int): Millis =
  Millis(m.uint64 div denominator.uint64)
