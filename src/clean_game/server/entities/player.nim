import
  ../../ecs/entity,
  ../../ecs/registry,
  ../../ecs/component,
  ../../ecs/components / [pos],
  ../../util/physical,
  ../global

type Player* = ref object
  entity*: Entity

proc newPlayer*(): Player =
  ## Create a new player entity
  Player(entity: global.reg.createEntity())

proc toPlayer*(entity: Entity): Player =
  ## Create a `Player` class from an existing entity
  Player(entity: entity)

proc spawn*(player: Player) =
  global.reg.assignComponent(
    player.entity,
    pos.Pos(data: vec2(20.0, 20.0))
  )

proc despawn*(player: Player) =
  global.reg.removeComponent(
    player.entity,
    CompClass.Pos
  )

proc move*(player: Player, offset: physical.Pos) =
  var posComp = pos.Pos(global.reg.componentOfEntity(
    player.entity,
    CompClass.Pos
  ))
  posComp.data += offset
