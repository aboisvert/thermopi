import asyncdispatch
export asyncdispatch

when defined(multithreaded):
  import sugar, threadpool
  proc callProcAndTrigger[IN; OUT](procName: string, p: proc (input: IN): OUT, input: IN, event: AsyncEvent): OUT =
    echo "Call " & procName
    result = p(input)
    event.trigger()
    echo "Called " & procName

  var outstanding = 0

  proc callAsync*[IN; OUT](
    procName: string,
    IN_TYPE: typedesc[IN],
    input: IN,
    OUT_TYPE: typedesc[OUT],
    p: proc (input: IN): OUT {.gcsafe, nimcall.}
  ): Future[OUT] {.async.} =
    let name = "callAsync:" & procName & " outstanding: " & $outstanding
    outstanding += 1
    let id = outstanding
    echo name
    let event = newAsyncEvent()
    var fut = newFuture[void]("callAsync:" & procName)
    GC_ref(fut)
    addEvent(event, (fd: AsyncFD) => (fut.complete(); true))
    let procResult: FlowVar[OUT] = spawn callProcAndTrigger(procName, p, input, event)
    await fut
    GC_unref(fut)
    outstanding -= 1
    echo "callAsync^" & procName & " id: " & $id & " outstanding: " & $outstanding
    result = ^procResult
    echo "result^" & procName & " id: " & $id & " outstanding: " & $outstanding
    close(event)

else: # not multithreaded
  proc callAsync*[IN; OUT](
    procName: string,
    IN_TYPE: typedesc[IN],
    input: IN,
    OUT_TYPE: typedesc[OUT],
    p: proc (input: IN): OUT {.gcsafe, nimcall.}
  ): Future[OUT] {.async.} =
    result = p(input)
