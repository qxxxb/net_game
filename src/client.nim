import
  clean_game/util / [logging, exceptions, physical, drawing],
  clean_game/client/input,
  clean_game/ecs,
  clean_game/ecs/registry,
  clean_game/ecs/components / [visible, pos, shape],
  clean_game/ecs/systems / [renderer],
  sdl2,
  sdl2/image as sdl2_image,
  options,
  os,
  glm

type Game = ref object
  reg: Registry

proc newGame(): Game =
  new result
  result.reg = newRegistry()

proc render(game: Game, renderer: RendererPtr) =
  renderSprites(
    renderer,
    game.reg
  )

type Client = ref object
  window: WindowPtr
  renderer: RendererPtr
  inputs: set[Input]
  game: Game

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

  result.renderer = createRenderer(
    result.window,
    -1,
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  result.game = newGame()

  discard result.renderer.setDrawColor(100, 100, 200, 255)

proc destroy(client: Client) =
  client.window.destroy()
  client.renderer.destroy()

proc update(client: Client) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      client.inputs.incl(Input.Quit)
    of KeyDown:
      let input = event.key.keysym.scancode.toInput()
      if input.isSome():
        client.inputs.incl(input.get())
    of KeyUp:
      let input = event.key.keysym.scancode.toInput()
      if input.isSome():
        client.inputs.excl(input.get())
    else:
      discard

proc render(client: Client) =
  client.renderer.clear()
  client.game.render(client.renderer)
  client.renderer.present()

proc main() =
  if not sdl2.init(INIT_EVERYTHING):
    sdlException("SDL2 initialization failed")
  defer: sdl2.quit()

  const imgFlags: cint = IMG_INIT_PNG
  if sdl2_image.init(imgFlags) != imgFlags:
    sdlException("SDL2 Image initialization failed")
  defer: sdl2_image.quit()

  var client = newClient()
  defer: client.destroy()

  let reg = client.game.reg
  let entity = reg.createEntity()
  let texture = client.renderer.loadTexture("assets" / "skins" / "coala.png")

  reg.assignComponent(
    entity,
    Visible(
      kind: visible.Kind.Sprite,
      tex: texture,
      texPosRect: drawing.initPosRect(0, 0, 96, 96),
      destRect: drawing.initRect(96, 96)
    )
  )

  reg.assignComponent(
    entity,
    pos.Pos(data: vec2(20.0, 20.0))
  )

  reg.assignComponent(
    entity,
    Shape(
      kind: shape.Kind.Rect,
      rect: vec2(96.0, 96.0)
    )
  )

  while Input.Quit notin client.inputs:
    client.update()
    client.render()

main()
