import
  sdl2,
  tables,
  sets,
  ../../ecs,
  ../../ecs/registry,
  ../components / [visible, pos, shape],
  ../../util / [physical, drawing]

proc renderSprites*(
  renderer: RendererPtr,
  reg: Registry
) =
  let entities = reg.entitiesOfClasses(
    CompClass.VisibleSprite,
    CompClass.Pos
  )

  for entity in entities:
    let sprite = Visible(
      reg.componentOfEntity(entity, CompClass.VisibleSprite)
    )

    let pos = pos.Pos(
      reg.componentOfEntity(entity, CompClass.Pos)
    )

    var srcRect = sprite.texPosRect
    var destRect = drawing.toPosRect(pos.toDrawingPos(), sprite.destRect)

    renderer.copyEx(
      sprite.tex,
      srcRect,
      destRect,
      angle = 0.0.cdouble(),
      center = nil,
      flip = SDL_FLIP_NONE
    )
