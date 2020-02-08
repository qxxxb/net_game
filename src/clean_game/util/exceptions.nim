import
  strformat,
  sdl2

type SDLException* = object of Exception

proc sdlException*(reason: string) =
  raise SDLException.newException(
    &"{reason}, SDL error: {sdl2.getError()}"
  )
