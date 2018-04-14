# thermopi-server

The server module is intended to run on a Raspberry Pi (Pi Zero W).

The server performs several roles:

1) Web-based UI
2) Data collection and persistence
3) Temperature control (via HVAC)


## Implementation

The server is implemented using the [Nim programming language](https://nim-lang.org) and the [Rosencrantz](https://github.com/andreaferretti/rosencrantz) web framework.

## Building

You can use the included `compile.sh` script.

Compilation is typically done through `nimble`:

```sh
% nimble c -d:controlPi src/thermopi.nim
```

The `controlPi` define is used to conditionally include actual GPIO control for your HVAC.  If you do not compile with this option, no actual hardware control will happen.    It is convenient to compile without this option when developing on your laptop/desktop.

## Dependencies

You need to install Wiring Pi, see http://wiringpi.com/download-and-install/

## Setting up as a SystemD Service

SystemD is used to manage services on Raspian.

See my [systemd-notes](systemd/systemd-notes.txt)

