import
  sdl2,
  sdl2/image as sdl2_image,
  os,
  ../../ecs/entity,
  ../../ecs/registry,
  ../../ecs/component,
  ../../ecs/components/[visible, shape],
  ../../ecs/components/pos as pos_comp,
  ../../util / [physical, drawing]

type Player* = ref object
  entity: Entity
  texture: TexturePtr

import ../global

proc newPlayer*(entity: Entity): Player =
  ## Returns a player with `entity`, regardless of whether the entity exists or
  ## not.
  Player(entity: entity)

proc isSpawned*(player: Player): bool =
  ## If the player is spawned, then it exists in the registry. If the
  ## player is not spawned, then it does not exist in the registry.

  ## TODO: There is a difference between spawning after being killed, and
  ## appearing on the screen because the server said so. For now, we are going
  ## with the latter, but this will likely need to be changed.
  global.reg.hasEntity(player.entity)

import ../controls/sources/keyboard

proc spawn*(player: Player) =
  global.reg.createEntity(player.entity)
  global.reg.tagEntity(player.entity, EntityTag.Player)

  ## TODO: This should not be in this function.
  ## TODO: Use a texture manager to avoid loading multiple times
  player.texture = global.renderer.loadTexture("assets" / "skins" / "coala.png")

  global.reg.assignComponent(
    player.entity,
    Visible(
      kind: visible.Kind.Sprite,
      tex: player.texture,
      texPosRect: drawing.initPosRect(0, 0, 96, 96),
      destRect: drawing.initRect(96, 96)
    )
  )

  global.reg.assignComponent(
    player.entity,
    pos_comp.Pos(data: vec2(20.0, 20.0))
  )

  global.reg.assignComponent(
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

proc despawn*(player: Player) =
  global.reg.removeEntity(player.entity)

proc setPos*(player: Player, pos: physical.Pos) =
  var posComp = pos_comp.Pos(
    global.reg.componentOfEntity(player.entity, CompClass.Pos)
  )

  posComp.data = pos
