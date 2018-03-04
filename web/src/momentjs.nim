import jsffi

##
## Moment.js FFI
## 

# Global `moment` module
type MomentModule* = ref object
var moment* {.importc, noDecl.}: MomentModule

# Untyped moment instance
type Moment* = JsObject

## Instantiate a `Moment` from a Unix epoch (seconds since epoch)
proc unix(moment: MomentModule, epoch: int): Moment {.importcpp: "#.unix(#)".}

## Format a Moment
## 
## moment.format("dddd, MMMM Do YYYY, h:mm:ss a"); // "Sunday, February 14th 2010, 3:25:50 pm"
## moment.format("ddd, hA");                       // "Sun, 3PM"
proc format*(moment: Moment, fmt: cstring): cstring {.importcpp: "#.format(#)".}

##
## Helpers
## 

proc fromUnix*(epoch: int): Moment =
  moment.unix(epoch)
