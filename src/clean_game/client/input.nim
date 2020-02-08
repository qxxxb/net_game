import sdl2, options

type
  Input* {.pure.} = enum
    Left, Right, Up, Down, Quit

proc toInput*(key: Scancode): Option[Input] =
  case key
  of SDL_SCANCODE_A: Input.Left.some()
  of SDL_SCANCODE_D: Input.Right.some()
  of SDL_SCANCODE_W: Input.Up.some()
  of SDL_SCANCODE_S: Input.Down.some()
  of SDL_SCANCODE_Q: Input.Quit.some()
  else: Input.none()
