import std/logging
export logging

proc initLogging*(name: string) =
  addHandler(newConsoleLogger())
  addHandler(
    newFileLogger(
      name & ".log",
      mode = fmWrite,
      levelThreshold = lvlAll,
      fmtStr = verboseFmtStr
    )
  )

  when defined release:
    setLogFilter(lvlInfo)
  else:
    setLogFilter(lvlInfo)
