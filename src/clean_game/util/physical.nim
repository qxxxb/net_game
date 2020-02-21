import
  glm,
  sdl2,
  ./drawing

type Pos* = Vec2[float]

type Rect* = Vec2[float]
proc width*(r: Rect): float = r.x
proc height*(r: Rect): float = r.y

type Circle* = object
  radius*: float
