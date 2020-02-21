import sdl2

type Pos* = sdl2.Point
proc initPos*(x, y: cint): Pos =
  (x, y)

# This is different from `sdl2.Rect` because this doesn't contain position
# information
type Rect* = tuple[w, h: cint]
proc width*(r: Rect): cint = r.w
proc height*(r: Rect): cint = r.h
proc initRect*(w, h: cint): Rect =
  (w, h)

# Rectangle with position
type PosRect* = sdl2.Rect

proc initPosRect*(x, y, w, h: cint): PosRect =
  sdl2.rect(x, y, w, h)

proc toPosRect*(pos: Point, rect: Rect): PosRect =
  initPosRect(pos.x, pos.y, rect.w, rect.h)
