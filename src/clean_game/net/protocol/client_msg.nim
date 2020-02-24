import
  logging,
  protobuf,
  os

parseProtoFile("src" / "clean_game" / "net" / "protocol" / "client_msg.proto")

export initClientMsg
export ClientMsgKind
export ClientMsg
export readClientMsg
export has
type GameInput* = ClientMsg_GameInput

proc `$`*(clientMsg: ClientMsg): string =
  # Write it to a stream
  var stream = newStringStream()
  stream.write(clientMsg)

  stream.setPosition(0)
  var readMsg = stream.readClientMsg()

  var fieldsStr: seq[string]

  if readMsg.has(kind):
    fieldsStr.add("kind: " & $readMsg.kind)

  if readMsg.has(gameInputs):
    fieldsStr.add("gameInputs: " & $readMsg.gameInputs)

  result = "ClientMsg: {" & fieldsStr.join(", ") & "}"

proc toProto*(clientMsg: ClientMsg): string =
  var stream = newStringStream()
  stream.write(clientMsg, writeSize = false)
  stream.setPosition(0)
  stream.readAll()

proc readClientMsg*(data: string): ClientMsg =
  var stream = newStringStream(data)
  stream.setPosition(0)
  result = stream.readClientMsg()
