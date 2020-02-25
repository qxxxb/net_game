import
  logging,
  strformat,
  net,
  nativesockets,
  tables,
  hashes,
  times,
  sets,
  options,
  ../util/ticks as ticks_m,
  ../server/global,
  ./protocol / [client_msg, server_msg],
  ../ecs/entity,
  ../server/entities/player,
  ../util/physical

type SendState {.pure.} = enum
  ## What is being sent to the client
  None,
  Connecting,
  GameSnapshot,
  Recovery

type RecvState {.pure.} = enum
  ## What is being received from the client
  None,
  GameInput

type ClientState = object
  sendState: SendState
  recvState: RecvState
  ackedTick: Tick # The last time that the client acked a snapshot, Units: tick

type ClientKey = object
  address: string
  port: Port

type Client = ref object
  state: ClientState
  msgsToSend: seq[ServerMsg]
  player: Option[Entity]

proc `$`(client: Client): string =
  # TODO: For some reason I need to implement this
  result =
    "Client: { state: " & $client.state &
    " msgsToSend: " & $client.msgsToSend & "}"

proc initClientKey(address: string, port: Port): ClientKey =
  ClientKey(
    address: address,
    port: port
  )

proc newClient(): Client =
  Client(
    state: ClientState(
      sendState: SendState.None,
      recvState: RecvState.None
    ),
    msgsToSend: newSeq[ServerMsg](),
  )

proc hash*(clientKey: ClientKey): Hash =
  var h: Hash = 0
  h = h !& hash(clientKey.address)
  h = h !& hash(clientKey.port)
  result = !$h

proc ticksSinceAck(client: Client): Tick =
  ## Duration since last ack, Units: ticks
  global.tick - client.state.ackedTick

# Number of ticks before running netcode. In other words, the number of ticks
# before receiving and sending packets.
# Units: ticks
const netPeriod = 1

proc ticksToDuration*(ticks: Tick): Duration =
  ticks.int64() * ticks_m.duration

proc shouldRunNet*(): bool =
  global.tick mod netPeriod == 0

proc shouldDisconnect(client: Client): bool =
  const preDisconnectDuration: Tick = netPeriod * 500
  client.ticksSinceAck() > preDisconnectDuration

proc shouldBeRecovery(client: Client): bool =
  const preRecoveryDuration: Tick = netPeriod * 50
  client.ticksSinceAck() > preRecoveryDuration

proc shouldSendSnapshot(client: Client): bool =
  proc snapshotPeriod(sendState: SendState): Tick =
    ## Duration between sending snapshots to clients in `sendState`.
    case sendState
    of SendState.Connecting: netPeriod * 10
    of SendState.Recovery: netPeriod * 50
    else: netPeriod

  proc snapshotPeriod(client: Client): Tick =
    client.state.sendState.snapshotPeriod()

  case client.state.sendState
  of SendState.GameSnapshot: true
  of SendState.Connecting, SendState.Recovery:
    debug "ackedTick: ", client.state.ackedTick
    debug "ticksSinceAck: ", client.ticksSinceAck()
    debug "snapShotPeriod: ", client.snapshotPeriod()
    client.ticksSinceAck() > client.snapshotPeriod()
  else: false

proc saveMsg*(client: Client, msg: ServerMsg) =
  ## Save a msg to send later
  client.msgsToSend.add(msg)

type Server* = ref object
  socketHandle: SocketHandle
  socket: Socket
  clients: TableRef[ClientKey, Client]

proc newServer*(): Server =
  Server(
    clients: newTable[ClientKey, Client]()
  )

proc open*(server: Server) =
  server.socketHandle = createNativeSocket(
    AF_INET,
    SOCK_DGRAM,
    IPPROTO_UDP
  )
  server.socket = newSocket(
    server.socketHandle,
    AF_INET,
    SOCK_DGRAM,
    IPPROTO_UDP
  )
  server.socketHandle.setBlocking(false)
  server.socket.bindAddr(Port(2000))

proc close*(server: Server) =
  server.socket.close()

proc sendInfo(server: Server, clientKey: ClientKey) =
  let msg = initServerMsg(kind = ServerMsgKind.Info)
  server.socket.sendTo(
    clientKey.address,
    clientKey.port,
    msg.toProto()
  )
  info &"Sent info to {clientKey.address}:{clientKey.port}"

proc connect(server: Server, clientKey: ClientKey) =
  if clientKey notin server.clients:
    var client = newClient()
    client.state.recvState = RecvState.GameInput
    client.state.sendState = SendState.Connecting
    client.state.ackedTick = global.tick
    server.clients[clientKey] = client
    info &"Connected {clientKey.address}:{clientKey.port}"

    var player = newPlayer()
    player.spawn()
    client.player = player.entity.some()
    info &"Spawned player with ID {client.player.get()}"
  else:
    warn "Got connect from already connected client"

proc disconnect(server: Server, clientKey: ClientKey) =
  if clientKey in server.clients:
    var client = server.clients[clientKey]
    if client.player.isSome():
      var player = newPlayer(client.player.get())
      player.despawn()
      info &"Despawned player with ID {client.player.get()}"
      client.player = Entity.none()

    server.clients.del(clientKey)
    info &"Disconnected {clientKey.address}:{clientKey.port}"
  else:
    warn "Got disconnect from unconnected client"

import
  ../ecs/registry

proc sendSnapshot(server: Server, clientKey: ClientKey) =
  var playerSnapshots: seq[ServerMsg_PlayerSnapshot]

  var playerEntities = global.reg.getEntitiesByTag(EntityTag.Player)
  for playerEntity in playerEntities:
    var player = newPlayer(playerEntity)
    let pos = player.getPos()
    var playerSnapshot = initServerMsg_PlayerSnapshot(
      id = playerEntity,
      posX = pos.x,
      posY = pos.y
    )
    playerSnapshots.add(playerSnapshot)

  var gameSnapshot = initServerMsg_GameSnapshot(
    tick = global.tick,
    playerSnapshots = playerSnapshots
  )

  var msg = initServerMsg(
    kind = ServerMsgKind.GameSnapshot,
    gameSnapshot = gameSnapshot
  )

  server.socket.sendTo(
    clientKey.address,
    clientKey.port,
    msg.toProto()
  )
  debug(
    &"Sent snapshot at tick {global.tick} to" &
    &" {clientKey.address}:{clientKey.port}"
  )

proc recv*(server: Server) =
  const data_capacity = 1024
  var data = newStringOfCap(data_capacity)
  var senderAddress: string
  var senderPort: Port
  var recvLen: int

  # Loop until there are no more messages in the socket
  while true:
    try:
      recvLen = server.socket.recvFrom(
        data,
        length = data_capacity,
        senderAddress,
        senderPort,
        flags = 0'i32
      )
    except OSError:
      break

    debug &"Recv [{senderAddress}:{senderPort}] ({recvLen})"

    var clientKey = initClientKey(senderAddress, senderPort)
    debug "Clients: ", server.clients

    var clientMsg = data.readClientMsg()
    debug &"clientMsg: {clientMsg}"

    if not clientMsg.has(kind):
      warn "Client msg has no `kind`, discarding"
      continue

    let kind = clientMsg.private_kind
    case kind
    of ClientMsgKind.RequestInfo:
      server.sendInfo(clientKey)
    of ClientMsgKind.Connect:
      server.connect(clientKey)
    of ClientMsgKind.Disconnect:
      server.disconnect(clientKey)
    of ClientMsgKind.Ack:
      if clientKey in server.clients:
        let ackedTick = clientMsg.private_ackedTick
        server.clients[clientKey].state.ackedTick = ackedTick
        server.clients[clientKey].state.sendState = SendState.GameSnapshot
        debug &"Acked snapshot {ackedTick} from {senderAddress}:{senderPort}"
      else:
        warn "Got ack from unconnected client"
    of ClientMsgKind.GameInput:
      # Check that client is connected
      if clientKey in server.clients:
        # TODO: Save inputs and process later, rather than processing right
        # here
        if clientMsg.has(gameInputs):
          let gameInputs = clientMsg.private_gameInputs
          let client = server.clients[clientKey]
          var player = newPlayer(client.player.get())
          for gameInput in gameInputs:
            let offset =
              case gameInput
              of GameInput.MoveLeft:
                vec2(-2.0, 0.0)
              of GameInput.MoveRight:
                vec2(2.0, 0.0)
              of GameInput.MoveUp:
                vec2(0.0, -2.0)
              of GameInput.MoveDown:
                vec2(0.0, 2.0)
            player.move(offset)
        else:
          warn "No game inputs in client msg"
      else:
        warn "Got game inputs from unconnected client"
      discard

proc send*(server: Server) =
  var clientsToDisconnect = initHashSet[ClientKey]()

  for clientKey, client in server.clients:
    debug "Pre-send"
    debug "client.sendState: ", client.state.sendState
    debug "client.recvState: ", client.state.recvState
    debug "client.ticksSinceAck(): ", client.ticksSinceAck()

    if client.shouldDisconnect():
      clientsToDisconnect.incl(clientKey)
    else:
      if client.shouldBeRecovery():
        server.clients[clientKey].state.sendState = SendState.Recovery

      if client.shouldSendSnapshot():
        server.sendSnapshot(clientKey)

  for clientKey in clientsToDisconnect:
    server.disconnect(clientKey)
