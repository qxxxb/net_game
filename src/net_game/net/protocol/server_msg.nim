import
  logging,
  protobuf,
  os

parseProtoFile("src" / "net_game" / "net" / "protocol" / "server_msg.proto")

export ServerMsg
export ServerMsgKind
# TODO: Aliasing these types causes problems
export ServerMsgPlayerSnapshot
export ServerMsgGameSnapshot

export initServerMsg
# TODO: I don't know how to alias these long macros
export initServerMsg_PlayerSnapshot
export initServerMsg_GameSnapshot

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

  # TODO: Print with nesting
  if readMsg.has(gameSnapshot):
    var gameSnapshot = readMsg.gameSnapshot
    if gameSnapshot.has(tick):
      fieldsStr.add("tick: " & $gameSnapshot.tick)
    if gameSnapshot.has(playerSnapshots):
      var playerSnapshots = gameSnapshot.playerSnapshots
      for playerSnapshot in playerSnapshots:
        if playerSnapshot.has(posX):
          fieldsStr.add("posX: " & $playerSnapshot.posX)
        if playerSnapshot.has(posY):
          fieldsStr.add("posY: " & $playerSnapshot.posY)

  result = "ServerMsg: {" & fieldsStr.join(", ") & "}"

proc toProto*(serverMsg: ServerMsg): string =
  var stream = newStringStream()
  stream.write(serverMsg, writeSize = false)
  stream.setPosition(0)
  stream.readAll()

proc readServerMsg*(data: string): ServerMsg =
  var stream = newStringStream(data)
  stream.setPosition(0)
  result = stream.readServerMsg()
