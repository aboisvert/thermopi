import asyncdispatch
export asyncdispatch

when defined(multithreaded):

  when not defined(threadsafe):
    {.fatal: "Must compile with both -d:threadsafe if -d:multithreaded is used".}

  import sugar, threadpool
  proc callProcAndTrigger[IN; OUT](procName: string, p: proc (input: IN): OUT, input: IN, event: AsyncEvent): OUT =
    echo "Call " & procName & " thread: " & $getThreadId()
    result = p(input)
    event.trigger()
    echo "Called " & procName & " thread: " & $getThreadId()

  var outstanding = 0
  var idTotal = 0

  proc callAsync*[IN; OUT](
    procName: string,
    IN_TYPE: typedesc[IN],
    input: IN,
    OUT_TYPE: typedesc[OUT],
    p: proc (input: IN): OUT {.gcsafe.}
  ): Future[OUT] {.async.} =
    idTotal += 1
    let id = idTotal
    echo "callAsync:" & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()
    outstanding += 1
    let event = newAsyncEvent()
    var fut = newFuture[void]("callAsync:" & procName & ":" & $id)
    GC_ref(fut)
    let fut_ptr = addr(fut)
    addEvent(event, (fd: AsyncFD) => (echo "complete " & procName & " id: " & $id & " thread: " & $getThreadId(); fut_ptr[].complete(); true))
    let procResult: FlowVar[OUT] = spawn callProcAndTrigger(procName, p, input, event)
    echo "before await fut " & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()
    await fut
    GC_unref(fut)
    echo "after await fut " & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()
    outstanding -= 1
    echo "before ^procResult " & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()
    result = ^procResult
    echo "after  ^procResult " & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()
    close(event)
    echo "after  close " & procName & " id: " & $id & " outstanding: " & $outstanding & " thread: " & $getThreadId()

else: # not multithreaded
  proc callAsync*[IN; OUT](
    procName: string,
    IN_TYPE: typedesc[IN],
    input: IN,
    OUT_TYPE: typedesc[OUT],
    p: proc (input: IN): OUT {.gcsafe, nimcall.}
  ): Future[OUT] {.async.} =
    result = p(input)
