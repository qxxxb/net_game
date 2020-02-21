import
  sdl2,
  sdl2/image as sdl2_image,
  os,
  ../entity,
  ../registry,
  ../components / [visible, pos, shape],
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
