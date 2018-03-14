##
##  wiringPi.h:
##   Arduino like Wiring library for the Raspberry Pi.
##   Copyright (c) 2012-2017 Gordon Henderson
## **********************************************************************
##  This file is part of wiringPi:
##   https://projects.drogon.net/raspberry-pi/wiringpi/
##
##     wiringPi is free software: you can redistribute it and/or modify
##     it under the terms of the GNU Lesser General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
##
##     wiringPi is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU Lesser General Public License for more details.
##
##     You should have received a copy of the GNU Lesser General Public License
##     along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
## **********************************************************************
##

##  C doesn't have true/false by default and I can never remember which
##   way round they are, so ...
##   (and yes, I know about stdbool.h but I like capitals for these and I'm old)

#const
#  FALSE* = (not TRUE)

##  GCC warning suppressor

#const
#  UNU* = __attribute__((unused))

##  Mask for the bottom 64 pins which belong to the Raspberry Pi
##   The others are available for the other devices

const
  PI_GPIO_MASK* = (0xFFFFFFC0)

##  Handy defines
##  wiringPi modes

const
  WPI_MODE_PINS* = 0
  WPI_MODE_GPIO* = 1
  WPI_MODE_GPIO_SYS* = 2
  WPI_MODE_PHYS* = 3
  WPI_MODE_PIFACE* = 4
  WPI_MODE_UNINITIALISED* = -1

##  Pin modes

const
  INPUT* = 0
  OUTPUT* = 1
  PWM_OUTPUT* = 2
  GPIO_CLOCK* = 3
  SOFT_PWM_OUTPUT* = 4
  SOFT_TONE_OUTPUT* = 5
  PWM_TONE_OUTPUT* = 6
  LOW* = 0
  HIGH* = 1

##  Pull up/down/none

const
  PUD_OFF* = 0
  PUD_DOWN* = 1
  PUD_UP* = 2

##  PWM

const
  PWM_MODE_MS* = 0
  PWM_MODE_BAL* = 1

##  Interrupt levels

const
  INT_EDGE_SETUP* = 0
  INT_EDGE_FALLING* = 1
  INT_EDGE_RISING* = 2
  INT_EDGE_BOTH* = 3

##  Pi model types and version numbers
##   Intended for the GPIO program Use at your own risk.

const
  PI_MODEL_A* = 0
  PI_MODEL_B* = 1
  PI_MODEL_AP* = 2
  PI_MODEL_BP* = 3
  PI_MODEL_2* = 4
  PI_ALPHA* = 5
  PI_MODEL_CM* = 6
  PI_MODEL_07* = 7
  PI_MODEL_3* = 8
  PI_MODEL_ZERO* = 9
  PI_MODEL_CM3* = 10
  PI_MODEL_ZERO_W* = 12
  PI_VERSION_1* = 0
  PI_VERSION_1_1* = 1
  PI_VERSION_1_2* = 2
  PI_VERSION_2* = 3
  PI_MAKER_SONY* = 0
  PI_MAKER_EGOMAN* = 1
  PI_MAKER_EMBEST* = 2
  PI_MAKER_UNKNOWN* = 3

var piModelNames* {.importc: "piModelNames", header: "wiringPi.h".}: array[16, cstring]

var piRevisionNames* {.importc: "piRevisionNames", header: "wiringPi.h".}: array[16,
    cstring]

var piMakerNames* {.importc: "piMakerNames", header: "wiringPi.h".}: array[16, cstring]

var piMemorySize* {.importc: "piMemorySize", header: "wiringPi.h".}: array[8, cint]

##   Intended for the GPIO program Use at your own risk.
##  Threads
## #define  PI_THREAD(X)	void *X (UNU void *dummy)
##  Failure modes

const
  WPI_FATAL* = (1 == 1)
  WPI_ALMOST* = (1 == 2)

##  wiringPiNodeStruct:
##   This describes additional device nodes in the extended wiringPi
##   2.0 scheme of things.
##   It's a simple linked list for now, but will hopefully migrate to
##   a binary tree for efficiency reasons - but then again, the chances
##   of more than 1 or 2 devices being added are fairly slim, so who
##   knows....

type
  wiringPiNodeStruct* {.importc: "wiringPiNodeStruct", header: "wiringPi.h", bycopy.} = object
    pinBase* {.importc: "pinBase".}: cint
    pinMax* {.importc: "pinMax".}: cint
    fd* {.importc: "fd".}: cint  ##  Node specific
    data0* {.importc: "data0".}: cuint ##   ditto
    data1* {.importc: "data1".}: cuint ##   ditto
    data2* {.importc: "data2".}: cuint ##   ditto
    data3* {.importc: "data3".}: cuint ##   ditto
    pinMode* {.importc: "pinMode".}: proc (node: ptr wiringPiNodeStruct; pin: cint;
                                       mode: cint)
    pullUpDnControl* {.importc: "pullUpDnControl".}: proc (
        node: ptr wiringPiNodeStruct; pin: cint; mode: cint)
    digitalRead* {.importc: "digitalRead".}: proc (node: ptr wiringPiNodeStruct;
        pin: cint): cint        ## unsigned int    (*digitalRead8)     (struct wiringPiNodeStruct *node, int pin) ;
    digitalWrite* {.importc: "digitalWrite".}: proc (node: ptr wiringPiNodeStruct;
        pin: cint; value: cint)  ##          void   (*digitalWrite8)    (struct wiringPiNodeStruct *node, int pin, int value) ;
    pwmWrite* {.importc: "pwmWrite".}: proc (node: ptr wiringPiNodeStruct; pin: cint;
        value: cint)
    analogRead* {.importc: "analogRead".}: proc (node: ptr wiringPiNodeStruct;
        pin: cint): cint
    analogWrite* {.importc: "analogWrite".}: proc (node: ptr wiringPiNodeStruct;
        pin: cint; value: cint)
    next* {.importc: "next".}: ptr wiringPiNodeStruct


var wiringPiNodes* {.importc: "wiringPiNodes", header: "wiringPi.h".}: ptr wiringPiNodeStruct

##  Function prototypes
##   c++ wrappers thanks to a comment by Nick Lott
##   (and others on the Raspberry Pi forums)

##  Data
##  Internal

proc wiringPiFailure*(fatal: cint; message: cstring): cint {.varargs,
    importc: "wiringPiFailure", header: "wiringPi.h".}
##  Core wiringPi functions

proc wiringPiFindNode*(pin: cint): ptr wiringPiNodeStruct {.
    importc: "wiringPiFindNode", header: "wiringPi.h".}
proc wiringPiNewNode*(pinBase: cint; numPins: cint): ptr wiringPiNodeStruct {.
    importc: "wiringPiNewNode", header: "wiringPi.h".}
proc wiringPiVersion*(major: ptr cint; minor: ptr cint) {.importc: "wiringPiVersion",
    header: "wiringPi.h".}
proc wiringPiSetup*(): cint {.importc: "wiringPiSetup", header: "wiringPi.h".}
proc wiringPiSetupSys*(): cint {.importc: "wiringPiSetupSys", header: "wiringPi.h".}
proc wiringPiSetupGpio*(): cint {.importc: "wiringPiSetupGpio", header: "wiringPi.h".}
proc wiringPiSetupPhys*(): cint {.importc: "wiringPiSetupPhys", header: "wiringPi.h".}
proc pinModeAlt*(pin: cint; mode: cint) {.importc: "pinModeAlt", header: "wiringPi.h".}
proc pinMode*(pin: cint; mode: cint) {.importc: "pinMode", header: "wiringPi.h".}
proc pullUpDnControl*(pin: cint; pud: cint) {.importc: "pullUpDnControl",
    header: "wiringPi.h".}
proc digitalRead*(pin: cint): cint {.importc: "digitalRead", header: "wiringPi.h".}
proc digitalWrite*(pin: cint; value: cint) {.importc: "digitalWrite",
                                        header: "wiringPi.h".}
proc digitalRead8*(pin: cint): cuint {.importc: "digitalRead8", header: "wiringPi.h".}
proc digitalWrite8*(pin: cint; value: cint) {.importc: "digitalWrite8",
    header: "wiringPi.h".}
proc pwmWrite*(pin: cint; value: cint) {.importc: "pwmWrite", header: "wiringPi.h".}
proc analogRead*(pin: cint): cint {.importc: "analogRead", header: "wiringPi.h".}
proc analogWrite*(pin: cint; value: cint) {.importc: "analogWrite",
                                       header: "wiringPi.h".}
##  PiFace specifics
##   (Deprecated)

proc wiringPiSetupPiFace*(): cint {.importc: "wiringPiSetupPiFace",
                                 header: "wiringPi.h".}
proc wiringPiSetupPiFaceForGpioProg*(): cint {.
    importc: "wiringPiSetupPiFaceForGpioProg", header: "wiringPi.h".}
##  Don't use this - for gpio program only
##  On-Board Raspberry Pi hardware specific stuff

proc piGpioLayout*(): cint {.importc: "piGpioLayout", header: "wiringPi.h".}
proc piBoardRev*(): cint {.importc: "piBoardRev", header: "wiringPi.h".}
##  Deprecated

proc piBoardId*(model: ptr cint; rev: ptr cint; mem: ptr cint; maker: ptr cint;
               overVolted: ptr cint) {.importc: "piBoardId", header: "wiringPi.h".}
proc wpiPinToGpio*(wpiPin: cint): cint {.importc: "wpiPinToGpio", header: "wiringPi.h".}
proc physPinToGpio*(physPin: cint): cint {.importc: "physPinToGpio",
                                       header: "wiringPi.h".}
proc setPadDrive*(group: cint; value: cint) {.importc: "setPadDrive",
    header: "wiringPi.h".}
proc getAlt*(pin: cint): cint {.importc: "getAlt", header: "wiringPi.h".}
proc pwmToneWrite*(pin: cint; freq: cint) {.importc: "pwmToneWrite",
                                       header: "wiringPi.h".}
proc pwmSetMode*(mode: cint) {.importc: "pwmSetMode", header: "wiringPi.h".}
proc pwmSetRange*(range: cuint) {.importc: "pwmSetRange", header: "wiringPi.h".}
proc pwmSetClock*(divisor: cint) {.importc: "pwmSetClock", header: "wiringPi.h".}
proc gpioClockSet*(pin: cint; freq: cint) {.importc: "gpioClockSet",
                                       header: "wiringPi.h".}
proc digitalReadByte*(): cuint {.importc: "digitalReadByte", header: "wiringPi.h".}
proc digitalReadByte2*(): cuint {.importc: "digitalReadByte2", header: "wiringPi.h".}
proc digitalWriteByte*(value: cint) {.importc: "digitalWriteByte",
                                   header: "wiringPi.h".}
proc digitalWriteByte2*(value: cint) {.importc: "digitalWriteByte2",
                                    header: "wiringPi.h".}
##  Interrupts
##   (Also Pi hardware specific)

proc waitForInterrupt*(pin: cint; mS: cint): cint {.importc: "waitForInterrupt",
    header: "wiringPi.h".}
proc wiringPiISR*(pin: cint; mode: cint; function: proc ()): cint {.
    importc: "wiringPiISR", header: "wiringPi.h".}
##  Threads

proc piThreadCreate*(fn: proc (a2: pointer): pointer): cint {.
    importc: "piThreadCreate", header: "wiringPi.h".}
proc piLock*(key: cint) {.importc: "piLock", header: "wiringPi.h".}
proc piUnlock*(key: cint) {.importc: "piUnlock", header: "wiringPi.h".}
##  Schedulling priority

proc piHiPri*(pri: cint): cint {.importc: "piHiPri", header: "wiringPi.h".}
##  Extras from arduino land

proc delay*(howLong: cuint) {.importc: "delay", header: "wiringPi.h".}
proc delayMicroseconds*(howLong: cuint) {.importc: "delayMicroseconds",
                                       header: "wiringPi.h".}
proc millis*(): cuint {.importc: "millis", header: "wiringPi.h".}
proc micros*(): cuint {.importc: "micros", header: "wiringPi.h".}