import
  ../../ecs/entity,
  ../../ecs/registry,
  ../../ecs/component,
  ../../ecs/components / [pos],
  ../../util/physical

type Player* = ref object
  entity*: Entity

import ../global

proc newPlayer*(): Player =
  ## Create a new player entity
  Player()

proc newPlayer*(entity: Entity): Player =
  ## Create a `Player` class from an existing entity
  Player(entity: entity)

proc isSpawned*(player: Player): bool =
  ## If the player is spawned, then it exists in the registry. If the
  ## player is not spawned, then it does not exist in the registry.
  global.reg.hasEntity(player.entity)

proc spawn*(player: Player) =
  player.entity = global.reg.createEntity()
  global.reg.tagEntity(player.entity, EntityTag.Player)

  global.reg.assignComponent(
    player.entity,
    pos.Pos(data: vec2(20.0, 20.0))
  )

proc despawn*(player: Player) =
  global.reg.removeEntity(player.entity)

proc move*(player: Player, offset: physical.Pos) =
  var posComp = pos.Pos(global.reg.componentOfEntity(
    player.entity,
    CompClass.Pos
  ))
  posComp.data += offset

proc getPos*(player: Player): physical.Pos =
  var posComp = pos.Pos(
    global.reg.componentOfEntity(player.entity, CompClass.Pos)
  )

  posComp.data
