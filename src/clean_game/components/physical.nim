import ../component

type Physical* = object of Component
  kind: ComponentKind.Physical

namespace Physical:
  type Rectangle*
    rectangle: Rectangle
