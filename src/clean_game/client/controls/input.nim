import
  strformat,
  ../../net/protocol,
  ../../net/client as net_client

type
  Input* {.pure.} = enum
    Left, Right, Up, Down,
    RequestInfo, Connect, Disconnect,
    Quit

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

proc processInputs*(
  inputs: set[Input],
  netClient: net_client.Client
) =
  for input in inputs:
    case input
    of Input.RequestInfo:
      let msg = Msg(kind: MsgKind.RequestInfo)
      netClient.saveMsg(msg)
    of Input.Connect:
      let msg = Msg(kind: MsgKind.Connect)
      netClient.saveMsg(msg)
    of Input.Disconnect:
      let msg = Msg(kind: MsgKind.Disconnect)
      netClient.saveMsg(msg)
    of Input.Left, Input.Right, Input.Up, Input.Down:
      let msg = Msg(
        kind: MsgKind.GameInput,
        data: input.toGameInput()
      )
      netClient.saveMsg(msg)
    else: discard
