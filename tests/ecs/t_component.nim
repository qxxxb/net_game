import
  unittest,
  clean_game/util / [physical, drawing],
  clean_game/ecs/component,
  clean_game/ecs/components / [visible, pos, shape]

suite "Component":
  test "Get class":
    let visible = Visible(
      kind: visible.Kind.Sprite,
      texPosRect: drawing.initPosRect(0, 0, 96, 96),
      destRect: drawing.initRect(96, 96)
    )

    let pos = pos.Pos(data: vec2(20.0, 20.0))

    let shape = Shape(
      kind: shape.Kind.Rect,
      rect: vec2(96.0, 96.0)
    )

    doAssert visible.getClass() == CompClass.VisibleSprite
    doAssert pos.getClass() == CompClass.Pos
    doAssert shape.getClass() == CompClass.ShapeRect
