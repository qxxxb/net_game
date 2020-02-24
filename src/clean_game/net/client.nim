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

proc requestInfo*(client: Client) =
  let msg = initClientMsg(kind = ClientMsgKind.RequestInfo)
  client.saveMsg(msg)
  client.state.recvState = RecvState.Info

proc connect*(client: Client) =
  let msg = initClientMsg(kind = ClientMsgKind.Connect)
  client.saveMsg(msg)
  client.state.recvState = RecvState.GameSnapshot

proc disconnect*(client: Client) =
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

proc sendMsgs*(client: Client) =
  ## Send saved msgs
  for msg in client.msgsToSend:
    echo "[sendMsgs] msg: ", msg
    var msgBytes = msg.toBytes()
    client.socket.sendTo(
      serverAddress,
      serverPort,
      data = msgBytes[0].addr(),
      size = msgBytes.len
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
        if kind == ServerMsgKind.GameSnapshot:
          if serverMsg.has(tick):
            let snapshotTick = serverMsg.private_tick
            info &"Received world snapshot at tick {snapshotTick}"
            let msg = initClientMsg(
              kind = ClientMsgKind.Ack,
              ackedTick = snapshotTick
            )
            client.saveMsg(msg)
            debug &"Saved (for sending) ack for tick {snapshotTick}"
          else:
            warn &"Game snapshot has no `tick`"
      else: discard
