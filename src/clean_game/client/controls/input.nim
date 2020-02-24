import
  strformat,
  ../../net/protocol/client_msg,
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
  var gameInputs = newSeq[GameInput]()
  for input in inputs:
    case input
    of Input.RequestInfo:
      let msg = initClientMsg(kind = ClientMsgKind.RequestInfo)
      netClient.saveMsg(msg)
    of Input.Connect:
      let msg = initClientMsg(kind = ClientMsgKind.Connect)
      netClient.saveMsg(msg)
    of Input.Disconnect:
      let msg = initClientMsg(kind = ClientMsgKind.Disconnect)
      netClient.saveMsg(msg)
    of Input.Left, Input.Right, Input.Up, Input.Down:
      gameInputs.add(input.toGameInput())
    else: discard

  if gameInputs.len > 0:
    let msg = initClientMsg(
      kind = ClientMsgKind.GameInput,
      gameInputs = gameInputs
    )
    netClient.saveMsg(msg)
