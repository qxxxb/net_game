import
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

  # Read the message from the stream and output the data if it's all present
  # TODO: return something even if it doesn't have the `gameInputs` field
  stream.setPosition(0)
  var readMsg = stream.readClientMsg()

  var fieldsStr: seq[string]

  if readMsg.has(kind):
    fieldsStr.add("kind: " & $readMsg.kind)

  if readMsg.has(gameInputs):
    fieldsStr.add("gameInputs: " & $readMsg.gameInputs)

  result = "ClientMsg: {" & fieldsStr.join(", ") & "}"

proc toBytes*(clientMsg: ClientMsg): seq[char] =
  var stream = newStringStream()
  stream.write(clientMsg, writeSize = false)

  result = newSeq[char](clientMsg.len + 1)
  stream.setPosition(0)
  let readLen = stream.readData(result[0].addr(), result.len)
  assert readLen == result.len
  assert stream.atEnd()
  stream.close()

proc readClientMsg*(bytes: seq[char]): ClientMsg =
  var stream = newStringStream()
  stream.writeData(bytes[0].unsafeAddr(), bytes.len * sizeof(char))
  stream.setPosition(0)
  result = stream.readClientMsg()

proc readClientMsg*(bytesString: string): ClientMsg =
  var stream = newStringStream(bytesString)
  stream.setPosition(0)
  result = stream.readClientMsg()
