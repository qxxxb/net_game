import
  glm,
  ../component,
  ../../util / [physical, drawing]

type Pos* = ref object of Component
  data*: physical.Pos

proc toDrawingPos*(pos: Pos): drawing.Pos =
  initPos(
    pos.data.x.toInt().cint(),
    pos.data.y.toInt().cint()
  )
