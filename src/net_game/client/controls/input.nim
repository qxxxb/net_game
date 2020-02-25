type
  Input* {.pure.} = enum
    Left, Right, Up, Down,
    RequestInfo, Connect, Disconnect,
    Quit

import
  strformat,
  ../../net/protocol/client_msg

proc toGameInput*(input: Input): GameInput =
  case input
  of Input.Left: GameInput.MoveLeft
  of Input.Right: GameInput.MoveRight
  of Input.Up: GameInput.MoveUp
  of Input.Down: GameInput.MoveDown
  else:
    raise ValueError.newException(
      &"Input `{input}` could not be converted to `GameInput`"
    )
