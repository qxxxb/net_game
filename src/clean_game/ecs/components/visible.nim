import
  sdl2,
  ../component,
  ../../util/drawing

type Kind* {.pure.} = enum
  Sprite

type Visible* = ref object of Component
  case kind*: Kind
  of Kind.Sprite:
    tex*: TexturePtr
    texPosRect*: drawing.PosRect ## Positioned rectangle on the texture
    destRect*: drawing.Rect ## \
      ## Rectangle on the window. The position is determined by the `Position`
      ## component.
