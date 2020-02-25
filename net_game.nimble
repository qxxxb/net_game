# Package

version       = "0.1.0"
author        = "qxxxb"
description   = "Networked multiplayer game"
license       = "MIT"
srcDir        = "src"
bin           = @["server", "client"]

# Dependencies

requires "nim >= 0.20.0", "sdl2", "glm", "protobuf"

task test, "Runs tests":
  exec "nim c -r tests/tester"
