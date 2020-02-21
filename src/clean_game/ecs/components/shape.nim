import
  glm,
  ../component,
  ../../util/physical

type Kind* {.pure.} = enum
  Rect,
  Circle

type Shape* = ref object of Component
  case kind*: Kind
  of Kind.Rect:
    rect*: Rect
  of Kind.Circle:
    circle*: Circle
