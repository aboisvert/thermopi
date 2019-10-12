import asyncdispatch, macros, sugar, threadpool
export asyncdispatch

macro callAsync*[T; U](TT: typedesc[T], input: T, UU: typedesc[U], f: proc (t: T): U): untyped =
  let await = ident("await")
  let fut = ident("fut")
  quote do:
    block:
      proc callp(evt: AsyncEvent, t: `TT`): `UU` =
        #echo "callp: " & $t
        let v = `f`(t)
        #echo "trigger: " & $v
        evt.trigger()
        v

      proc async_call(input: `TT`): Future[`UU`] {.async.} =
        let evt = newAsyncEvent()
        let `fut` = callAsyncAwait(evt)
        #echo "before spawn: " & $input
        let val = spawn callp(evt, input)
        #echo "after spawn: " & $input
        `await` `fut`
        let v = ^val
        #echo "after await: " & $v
        return v

      async_call(`input`)

proc callAsyncAwait*(evt: AsyncEvent): Future[void] =
  var fut = newFuture[void]("callAsync")
  addEvent(evt, (fd: AsyncFD) => (fut.complete(); true))
  return fut
