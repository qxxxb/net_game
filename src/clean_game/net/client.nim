import
  logging,
  net,
  nativesockets,
  ./protocol

# TODO: should this be in `protocol`?
type MsgKind* {.pure.} = enum
  RequestInfo,
  Connect,
  Disconnect,
  GameInput

type Msg* = object
  case kind*: MsgKind
  of MsgKind.GameInput:
    data*: GameInput
  else: discard

type Client* = ref object
  gameInputs: set[GameInput]
  socketFd: SocketHandle
  socket: Socket
  msgs: seq[Msg] ## Msgs to send

proc newClient*(): Client =
  Client(
    msgs: newSeq[Msg]()
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

proc saveMsg*(client: Client, msg: Msg) =
  ## Save a msg to send later
  client.msgs.add(msg)

proc sendMsgs*(client: Client) =
  ## TODO: Send saved msgs
  for msg in client.msgs:
    echo "msg: ", msg

  client.msgs.setLen(0)

proc recv*(client: Client) =
  discard
