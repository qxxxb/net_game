import
  logging,
  net,
  nativesockets,
  strformat,
  ./protocol / [client_msg, server_msg]

type RecvState {.pure.} = enum
  ## What is being received from the server
  None,
  Info,
  GameSnapshot

type State = object
  recvState: RecvState

type Client* = ref object
  gameInputs: set[GameInput]
  socketFd: SocketHandle
  socket: Socket
  msgsToSend: seq[ClientMsg]
  state: State

proc newClient*(): Client =
  Client(
    msgsToSend: newSeq[ClientMsg](),
    state: State(
      recvState: RecvState.None
    )
  )

proc open*(client: Client) =
  client.socketFd = createNativeSocket(
    AF_INET,
    SOCK_DGRAM,
    IPPROTO_UDP
  )
  client.socket = newSocket(
    client.socketFd,
    AF_INET,
    SOCK_DGRAM,
    IPPROTO_UDP
  )
  client.socketFd.setBlocking(false)

proc close*(client: Client) =
  client.socket.close()

# TODO: Don't hardcode this
const serverAddress = "localhost"
let serverPort = Port(2000)

proc saveMsg*(client: Client, msg: ClientMsg) =
  ## Save a msg to send later
  client.msgsToSend.add(msg)

import
  ../util/physical,
  ../ecs/entity,
  ../ecs/registry,
  ../client/entities/player,
  ../client/global

proc requestInfo*(client: Client) =
  let msg = initClientMsg(kind = ClientMsgKind.RequestInfo)
  client.saveMsg(msg)
  client.state.recvState = RecvState.Info

proc connect*(client: Client) =
  let msg = initClientMsg(kind = ClientMsgKind.Connect)
  client.saveMsg(msg)
  client.state.recvState = RecvState.GameSnapshot

proc disconnect*(client: Client) =
  var playerEntity = global.reg.getEntityByTag(EntityTag.Player)
  var player = newPlayer(playerEntity)
  if player.isSpawned():
    player.despawn()

  let msg = initClientMsg(kind = ClientMsgKind.Disconnect)
  client.saveMsg(msg)
  client.state.recvState = RecvState.None

proc sendGameInputs*(client: Client, gameInputs: seq[GameInput]) =
  if gameInputs.len > 0:
    let msg = initClientMsg(
      kind = ClientMsgKind.GameInput,
      gameInputs = gameInputs
    )
    client.saveMsg(msg)

proc processPlayerSnapshot*(
  client: Client,
  playerSnapshot: ServerMsg_PlayerSnapshot
) =
  var entity: Entity
  var pos: physical.Pos

  if playerSnapshot.has(id):
    entity = playerSnapshot.private_id
  else:
    warn "Player snapshot missing ID"
    return

  if playerSnapshot.has(posX):
    pos.x = playerSnapshot.private_posX
  else:
    warn "Player snapshot missing posX"
    return

  if playerSnapshot.has(posY):
    pos.y = playerSnapshot.private_posY
  else:
    warn "Player snapshot missing posY"
    return

  info &"Player [{entity}]: pos: ({pos.x}, {pos.y})"
  var player = newPlayer(entity)
  if not player.isSpawned():
    player.spawn()

  player.setPos(pos)

proc processPlayerSnapshots*(
  client: Client,
  playerSnapshots: openArray[ServerMsg_PlayerSnapshot]
) =
  for playerSnapshot in playerSnapshots:
    client.processPlayerSnapshot(playerSnapshot)

proc processGameSnapshot*(
  client: Client,
  gameSnapshot: ServerMsg_GameSnapshot
) =
  if gameSnapshot.has(tick):
    let snapshotTick = gameSnapshot.private_tick
    info &"Received world snapshot at tick {snapshotTick}"
    let msg = initClientMsg(
      kind = ClientMsgKind.Ack,
      ackedTick = snapshotTick
    )
    client.saveMsg(msg)
    debug &"Saved (for sending) ack for tick {snapshotTick}"

    if gameSnapshot.has(playerSnapshots):
      let playerSnapshots = gameSnapshot.private_playerSnapshots
      client.processPlayerSnapshots(playerSnapshots)
  else:
    warn "Game snapshot has no `tick`"

proc processGameSnapshot*(
  client: Client,
  serverMsg: ServerMsg
) =
  ## Expects `serverMsg.kind` to be `ServerMsgKind.GameSnapshot`
  if serverMsg.has(gameSnapshot):
    var gameSnapshot = serverMsg.private_gameSnapshot
    client.processGameSnapshot(gameSnapshot)
  else:
    warn "Server msg has no game snapshot"

proc sendMsgs*(client: Client) =
  ## Send saved msgs
  for msg in client.msgsToSend:
    debug "[sendMsgs] msg: ", msg
    client.socket.sendTo(
      serverAddress,
      serverPort,
      msg.toProto()
    )

  client.msgsToSend.setLen(0)

proc recv*(client: Client) =
  case client.state.recvState
  of RecvState.None: discard
  else:
    const data_capacity = 1024
    var data = newStringOfCap(data_capacity)
    var senderAddress: string
    var senderPort: Port
    var recvLen: int

    while true:
      try:
        recvLen = client.socket.recvFrom(
          data,
          length = data_capacity,
          address = senderAddress,
          port = senderPort,
          flags = 0'i32
        )
      except OSError:
        break

      info &"Recv [{senderAddress}:{senderPort}] ({recvLen}): {data}"

      # TODO: Verify that sender is server.
      # Don't know if this is necessary

      var serverMsg = data.readServerMsg()
      debug &"serverMsg: {serverMsg}"

      if not serverMsg.has(kind):
        warn "Server msg has no `kind`, discarding"
        continue

      let kind = serverMsg.private_kind

      # Process the data
      case client.state.recvState
      of RecvState.Info:
        if kind == ServerMsgKind.Info:
          # TODO: Print server info from `serverMsg`
          info &"Server info: {serverMsg}"

      of RecvState.GameSnapshot:
        client.processGameSnapshot(serverMsg)

      else: discard
