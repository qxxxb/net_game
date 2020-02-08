# Package

version       = "0.1.0"
author        = "qxxxb"
description   = "A clean game"
license       = "MIT"
srcDir        = "src"
bin           = @["server", "client"]

# Dependencies

requires "nim >= 0.20.0", "sdl2"
