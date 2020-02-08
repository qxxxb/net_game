import
  sdl2,
  glm,
  ../component

type VisibleKind* {.pure.} = enum
  Sprite,
  Shaded

type Vk = VisibleKind

type ShaderKind* {.pure.} = enum
  Solid,
  Gradient

type Visible* = object of Component
  case kind: VisibleKind
  of Vk.Sprite:
    texture: TexturePtr
    textureCoordinates: Vec2[float]
  of Vk.Shaded:
    shader: ShaderKind
