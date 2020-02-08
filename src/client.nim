import
  clean_game/util / [logging, exceptions],
  clean_game/client/input,
  sdl2,
  options

type Game = ref object
  window: WindowPtr
  renderer: RendererPtr
  inputs: set[Input]

proc newGame(): Game =
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

  discard result.renderer.setDrawColor(100, 100, 200, 255)

proc destroy(game: Game) =
  game.window.destroy()
  game.renderer.destroy()

proc update(game: Game) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      game.inputs.incl(Input.Quit)
    of KeyDown:
      let input = event.key.keysym.scancode.toInput()
      if input.isSome():
        game.inputs.incl(input.get())
    of KeyUp:
      let input = event.key.keysym.scancode.toInput()
      if input.isSome():
        game.inputs.excl(input.get())
    else:
      discard

proc render(game: Game) =
  game.renderer.clear()
  game.renderer.present()

proc main() =
  if not sdl2.init(INIT_EVERYTHING):
    sdlException("SDL2 initialization failed")

  var game = newGame()
  defer: game.destroy()

  while Input.Quit notin game.inputs:
    game.update()
    game.render()

main()
