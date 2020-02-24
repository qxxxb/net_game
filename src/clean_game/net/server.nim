import
  logging,
  strformat,
  net,
  nativesockets,
  tables,
  hashes,
  times,
  sets,
  ../util/ticks as ticks_m,
  ../server/global,
  ./protocol/client_msg

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

type Client = object
  state: ClientState

proc initClientKey(address: string, port: Port): ClientKey =
  ClientKey(
    address: address,
    port: port
  )

proc initClient(): Client =
  Client(
    state: ClientState(
      sendState: SendState.None,
      recvState: RecvState.None
    )
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
  server.socket.sendTo(clientKey.address, clientKey.port, "Welcome to my server")
  info &"Sent info to {clientKey.address}:{clientKey.port}"

proc connect(server: Server, clientKey: ClientKey) =
  var client = initClient()
  client.state.recvState = RecvState.GameInput
  client.state.sendState = SendState.Connecting
  server.clients[clientKey] = client
  info &"Connected {clientKey.address}:{clientKey.port}"

proc disconnect(server: Server, clientKey: ClientKey) =
  if clientKey in server.clients:
    server.clients.del(clientKey)
    info &"Disconnected {clientKey.address}:{clientKey.port}"
  else:
    warn "Got disconnect from unconnected client"

proc sendSnapshot(server: Server, clientKey: ClientKey) =
  server.socket.sendTo(
    clientKey.address,
    clientKey.port,
    &"[{global.tick}] World snapshot"
  )
  info(
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
      debug &"No messages in socket ({recvLen})"
      break

    if recvLen > 0:
      info &"Recv [{senderAddress}:{senderPort}] ({recvLen}): `{data}`"
      var clientMsg = data.readClientMsg()
      info &"clientMsg: {clientMsg}"

      # var clientKey = initClientKey(senderAddress, senderPort)
      # debug "Clients: ", server.clients

      # type ParsedData = object
      #   ackedTick: int

      # var parsedData = ParsedData()

      # if data == "Info request":
      #   server.sendInfo(clientKey)
      # elif data == "Connect":
      #   server.connect(clientKey)
      # elif data == "Disconnect":
      #   server.disconnect(clientKey)
      # elif data.scanf("[$i] Ack", parsedData.ackedTick):
      #   if clientKey in server.clients:
      #     let ackedTick = parsedData.ackedTick.Tick()
      #     server.clients[clientKey].state.ackedTick = ackedTick
      #     server.clients[clientKey].state.sendState = SendState.GameSnapshot
      #     info &"Acked snapshot {ackedTick} from {senderAddress}:{senderPort}"
      #   else:
      #     warn "Got ack from unconnected client"

      # else:
      #   # TODO: Save inputs and process
      #   discard

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
