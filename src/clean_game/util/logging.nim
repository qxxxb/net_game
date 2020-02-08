import std/logging
export logging

proc initLogging*() =
  addHandler(newConsoleLogger())
  when defined release:
    setLogFilter(lvlInfo)
