import
  logging,
  protobuf,
  os

parseProtoFile("src" / "clean_game" / "net" / "protocol" / "server_msg.proto")

export initServerMsg
export ServerMsgKind
export ServerMsg
export readServerMsg
export has

proc `$`*(serverMsg: ServerMsg): string =
  # Write it to a stream
  var stream = newStringStream()
  stream.write(serverMsg)

  stream.setPosition(0)
  var readMsg = stream.readServerMsg()

  var fieldsStr: seq[string]

  if readMsg.has(kind):
    fieldsStr.add("kind: " & $readMsg.kind)

  if readMsg.has(tick):
    fieldsStr.add("tick: " & $readMsg.tick)

  result = "ServerMsg: {" & fieldsStr.join(", ") & "}"

proc toBytes*(serverMsg: ServerMsg): seq[char] =
  var stream = newStringStream()
  stream.write(serverMsg, writeSize = false)

  result = newSeq[char](serverMsg.len + 1)
  stream.setPosition(0)
  let readLen = stream.readData(result[0].addr(), result.len)
  if readLen != result.len:
    warn "[toBytes] readLen != result.len"
  if not stream.atEnd():
    warn "[toBytes] not stream.atEnd()"
  stream.close()

proc readServerMsg*(bytes: seq[char]): ServerMsg =
  var stream = newStringStream()
  stream.writeData(bytes[0].unsafeAddr(), bytes.len * sizeof(char))
  stream.setPosition(0)
  result = stream.readServerMsg()

proc readServerMsg*(bytesString: string): ServerMsg =
  var stream = newStringStream(bytesString)
  stream.setPosition(0)
  result = stream.readServerMsg()
