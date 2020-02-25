import
  sdl2,
  options,
  tables,
  hashes,
  times,
  ../input

export input

## Process keyboard events and convert them to `input`.

type Key* = sdl2.Scancode

type KeyState* {.pure.} = enum
  Pressed, Unheld, Held, Released

type KeyAction* = object
  key: Key
  keyState: KeyState

proc hash*(key: Key): Hash =
  var h: Hash = 0
  h = h !& key.int().hash
  result = !$h

proc hash*(keyAction: KeyAction): Hash =
  var h: Hash = 0
  h = h !& keyAction.key.hash()
  h = h !& keyAction.keyState.hash()
  result = !$h

type Keyboard* = ref object
  keyStartTimes: TableRef[Key, Time]
  keys: array[KeyState, set[Key]]
  toInput: TableRef[KeyAction, set[Input]]

proc newKeyboard*(): Keyboard =
  Keyboard(
    keyStartTimes: newTable[Key, Time](),
    toInput: newTable[KeyAction, set[Input]]()
  )

const preHeldDuration* = initDuration(milliseconds = 500) ## \
  ## Duration between when a key is first pressed and when it is considered to
  ## be held

proc addInput*(
  keyboard: Keyboard,
  key: Key,
  keyState: KeyState,
  input: Input,
) =
  let keyAction = KeyAction(
    key: key,
    keyState: keyState
  )
  if keyboard.toInput.hasKeyOrPut(keyAction, {input}):
    keyboard.toInput[keyAction].incl(input)

proc onKeyDown*(keyboard: Keyboard, key: Scancode) =
  let now = times.getTime()
  if key in keyboard.keys[KeyState.Pressed]:
    let startTime = keyboard.keyStartTimes[key]
    let elapsed = now - startTime
    if elapsed > preHeldDuration:
      keyboard.keys[KeyState.Held].incl(key)
  else:
    keyboard.keys[KeyState.Pressed].incl(key)
    keyboard.keys[KeyState.Unheld].incl(key)
    keyboard.keyStartTimes[key] = now

  keyboard.keys[KeyState.Released].excl(key)

proc onKeyUp*(keyboard: Keyboard, key: Scancode) =
  keyboard.keys[KeyState.Pressed].excl(key)
  keyboard.keys[KeyState.Unheld].excl(key)
  keyboard.keys[KeyState.Held].excl(key)
  keyboard.keys[KeyState.Released].incl(key)

proc updateKeys*(keyboard: Keyboard) =
  ## Run this at the beginning of the game loop
  keyboard.keys[KeyState.Unheld] = {}
  keyboard.keys[KeyState.Released] = {}

proc processKeys*(keyboard: Keyboard, inputs: var set[Input]) =
  inputs = {}
  for keyState, keys in keyboard.keys:
    for key in keys:
      let keyAction = KeyAction(
        key: key,
        keyState: keyState
      )
      if keyboard.toInput.hasKey(keyAction):
        let input: set[Input] = keyboard.toInput[keyAction]
        inputs.incl(input)
