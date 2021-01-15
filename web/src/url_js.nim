import jsffi, strformat

##
## Trivial FFI for Javascript's builtin URL
##

type URL* = JsObject

proc newURL*(url: cstring): URL {.importcpp: "new URL(@)".}
proc newURL*(url: JsObject): URL {.importcpp: "new URL(@)".}

var location* {.importc: "window.location".}: JsObject

type QueryParams* = object
  wrapped: JsObject

proc queryParams*(): QueryParams =
  let params = newURL(location.href).searchParams
  QueryParams(wrapped: params)

proc get*(params: QueryParams, param: cstring): cstring =
  cast[cstring](params.wrapped.get(param))

proc httpApi*(): cstring =
 let protocol = cast[cstring](location.protocol)
 let host = cast[cstring](location.hostname)
 let port = cast[cstring](location.port)
 fmt"{protocol}//{host}:{port}/api"
