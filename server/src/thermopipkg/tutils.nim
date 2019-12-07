
template measure*(str: string, body: untyped): untyped =
  let start = cpuTime()
  let result = body
  let stop = cpuTime()
  echo str & " - " & $(stop-start)
  result
  