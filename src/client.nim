import
  sdl2,
  sdl2/image as sdl2_image,
  options,
  os,
  times,
  clean_game/util / [logging, exceptions, physical, drawing, ticks],
  clean_game/client/controls/sources/keyboard,
  clean_game/client/global,
  clean_game/ecs,
  clean_game/ecs/registry,
  clean_game/client/entities / [player],
  clean_game/ecs/systems / [renderer],
  clean_game/net/client as net_client,
  clean_game/net/protocol/client_msg

type Game = ref object
  ## Nothing here

proc newGame(): Game =
  new result
  global.reg = newRegistry()

proc render(game: Game, renderer: RendererPtr) =
  renderSprites(
    renderer,
    global.reg
  )

type Client = ref object
  window: WindowPtr
  inputs: set[Input]
  game: Game
  netClient*: net_client.Client

proc newClient(): Client =
  new result
  result.window = createWindow(
    "SDL Skeleton",
    100,
    100,
    640,
    480,
    SDL_WINDOW_SHOWN
  )

  global.renderer = createRenderer(
    result.window,
    -1,
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  discard global.renderer.setDrawColor(100, 100, 200, 255)

  global.keyboard = newKeyboard()
  global.keyboard.addInput(
    SDL_SCANCODE_Q,
    keyboard.KeyState.Unheld,
    Input.Quit
  )
  global.keyboard.addInput(
    SDL_SCANCODE_I,
    keyboard.KeyState.Unheld,
    Input.RequestInfo
  )
  global.keyboard.addInput(
    SDL_SCANCODE_C,
    keyboard.KeyState.Unheld,
    Input.Connect
  )
  global.keyboard.addInput(
    SDL_SCANCODE_V,
    keyboard.KeyState.Unheld,
    Input.Disconnect
  )

  result.game = newGame()

  result.netClient = net_client.newClient()
  result.netClient.open()

proc destroy(client: Client) =
  client.netClient.close()
  client.window.destroy()
  global.renderer.destroy()

proc update(client: Client) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      # TODO
      client.inputs.incl(Input.Quit)
    of KeyDown:
      let key = event.key.keysym.scancode
      global.keyboard.onKeyDown(key)
    of KeyUp:
      let key = event.key.keysym.scancode
      global.keyboard.onKeyUp(key)
    else:
      discard

proc processInputs*(client: Client) =
  var netClient = client.netClient
  var gameInputs = newSeq[GameInput]()
  for input in client.inputs:
    case input
    of Input.RequestInfo:
      netClient.requestInfo()
    of Input.Connect:
      netClient.connect()
    of Input.Disconnect:
      netClient.disconnect()
    of Input.Left, Input.Right, Input.Up, Input.Down:
      gameInputs.add(input.toGameInput())
    else: discard

  netClient.sendGameInputs(gameInputs)

proc render(client: Client) =
  global.renderer.clear()
  client.game.render(global.renderer)
  global.renderer.present()

proc main() =
  initLogging("client")

  if not sdl2.init(INIT_EVERYTHING):
    sdlException("SDL2 initialization failed")
  defer: sdl2.quit()

  const imgFlags: cint = IMG_INIT_PNG
  if sdl2_image.init(imgFlags) != imgFlags:
    sdlException("SDL2 Image initialization failed")
  defer: sdl2_image.quit()

  var client = newClient()
  defer: client.destroy()

  # var player = newPlayer(global.reg, global.renderer)
  # player.spawn(global.reg)

  while Input.Quit notin client.inputs:
    let tickStart = times.getTime()
    global.keyboard.updateKeys()
    client.netClient.recv()
    client.update()
    global.keyboard.processKeys(client.inputs)
    client.processInputs()
    client.netClient.sendMsgs()
    client.render()

    # Sleep until next tick needed
    let elapsed = times.getTime() - tickStart
    let sleepDuration = ticks.duration - elapsed
    if (sleepDuration > DurationZero):
      sleep(sleepDuration.inMilliseconds().int())
    else:
      warn "Tick ran for longer than `tickDuration`"
      warn "`tickDuration - elapsed`: ", sleepDuration

main()
