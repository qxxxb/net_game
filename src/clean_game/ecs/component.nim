type Component* = ref object of RootObj

import ./components / [visible, shape, pos]

type CompClass* {.pure.} = enum
  VisibleSprite,
  ShapeRect,
  ShapeCircle,
  Pos

type CompInterface* {.pure.} = enum
  Visible,
  Shape,
  Pos

proc getClass*[T: Component](comp: T): CompClass =
  when comp is Visible:
    case comp.kind
    of visible.Kind.Sprite: return CompClass.VisibleSprite
  elif comp is Shape:
    case comp.kind
    of shape.Kind.Rect: return CompClass.ShapeRect
    of shape.Kind.Circle: return CompClass.ShapeCircle
  elif comp is Pos:
    return CompClass.Pos

proc getInterface*[T: Component](comp: T): CompInterface =
  when comp is Visible:
    CompInterface.Visible
  elif comp is Shape:
    CompInterface.Shape
  elif comp is Pos:
    CompInterface.Pos

proc `$`*(comp: Component): string =
  "Component"
