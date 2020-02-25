import ../ecs/registry
var reg*: Registry

import sdl2
var renderer*: sdl2.RendererPtr

import ./controls/sources/keyboard as keyboard_m
var keyboard*: Keyboard
