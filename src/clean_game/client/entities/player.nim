import
  sdl2,
  sdl2/image as sdl2_image,
  os,
  ../../ecs/entity,
  ../../ecs/registry,
  ../../ecs/components / [visible, pos, shape],
  ../controls/sources/keyboard,
  ../global,
  ../../util / [physical, drawing]

type Player* = ref object
  entity: Entity
  texture: TexturePtr

proc newPlayer*(
  reg: Registry,
  renderer: sdl2.RendererPtr
): Player =
  Player(
    entity: reg.createEntity(),
    texture: renderer.loadTexture("assets" / "skins" / "coala.png")
  )

proc spawn*(player: Player, reg: Registry) =
  reg.assignComponent(
    player.entity,
    Visible(
      kind: visible.Kind.Sprite,
      tex: player.texture,
      texPosRect: drawing.initPosRect(0, 0, 96, 96),
      destRect: drawing.initRect(96, 96)
    )
  )

  reg.assignComponent(
    player.entity,
    pos.Pos(data: vec2(20.0, 20.0))
  )

  reg.assignComponent(
    player.entity,
    Shape(
      kind: shape.Kind.Rect,
      rect: vec2(96.0, 96.0)
    )
  )

  global.keyboard.addInput(
    SDL_SCANCODE_A,
    keyboard.KeyState.Pressed,
    Input.Left
  )

  global.keyboard.addInput(
    SDL_SCANCODE_D,
    keyboard.KeyState.Pressed,
    Input.Right
  )

  global.keyboard.addInput(
    SDL_SCANCODE_W,
    keyboard.KeyState.Pressed,
    Input.Up
  )

  global.keyboard.addInput(
    SDL_SCANCODE_S,
    keyboard.KeyState.Pressed,
    Input.Down
  )
