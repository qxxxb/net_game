import
  logging,
  net,
  nativesockets,
  ./protocol/client_msg

type Client* = ref object
  gameInputs: set[GameInput]
  socketFd: SocketHandle
  socket: Socket
  msgsToSend: seq[ClientMsg]

proc newClient*(): Client =
  Client(
    msgsToSend: newSeq[ClientMsg]()
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

proc sendMsgs*(client: Client) =
  ## TODO: Send saved msgs
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
  discard
