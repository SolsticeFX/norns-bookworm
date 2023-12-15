--
-- NornsInput
--

--TOATDO

local NornsInput = sky.InputBase:extend()
NornsInput.KEY_EVENT = 'KEY'
NornsInput.ENC_EVENT = 'ENC'
NornsInput.TOUCH_EVENT = 'TOUCH'
NornsInput.PRESS_EVENT = 'PRESS'
NornsInput.RELEASE_EVENT = 'RELEASE'
NornsInput.TAP_EVENT = 'TAP'
NornsInput.DRAG_EVENT = 'DRAG'
NornsInput.REDRAW_EVENT = 'REDRAW'

local SingletonInput = nil
local is_focused = true

local function do_key(...)
  if SingletonInput then SingletonInput:on_key_event(...) end
end

local function do_enc(...)
  if SingletonInput then SingletonInput:on_enc_event(...) end
end

local function do_touch(...)
  if SingletonInput then SingletonInput:on_touch_event(...) end
end

local function do_press(...)
  if SingletonInput then SingletonInput:on_press_event(...) end
end
local function do_release(...)
  if SingletonInput then SingletonInput:on_release_event(...) end
end
local function do_tap(...)
  if SingletonInput then SingletonInput:on_tap_event(...) end
end
local function do_drag(...)
  if SingletonInput then SingletonInput:on_drag_event(...) end
end

local function do_redraw()
  if SingletonInput then SingletonInput:on_redraw() end
end

local function has_focus()
  -- test to see if our redraw method has been replaced, if so we've lost focus
  -- and the menu taken over redraw
  return redraw == do_redraw and is_focused
end

-- helpers to control enable/disable redraw explictly
local function set_focus(bool)
  is_focused = bool
end

function NornsInput:new(props)
  NornsInput.super.new(self, props)
  -- note this (re)defined script global handlers
  key = do_key
  enc = do_enc
  touch = do_touch
  redraw = do_redraw
  press = do_press
  release = do_release
  tap = do_tap
  drag = do_drag

  self._redraw_event = self.mk_redraw()
end

function NornsInput.mk_key(n, z)
  return { type = NornsInput.KEY_EVENT, n = n, z = z }
end

function NornsInput.is_key(event)
  return event.type == NornsInput.KEY_EVENT
end

function NornsInput.mk_enc(n, delta)
  return { type = NornsInput.ENC_EVENT, n = n, delta = delta }
end

function NornsInput.is_enc(event)
  return event.type == NornsInput.ENC_EVENT
end

function NornsInput.mk_touch(slot,press,x,y)
  return { type = NornsInput.TOUCH_EVENT, slot = slot, press = press, x = x, y = y }
end

function NornsInput.is_touch(event)
  return event.type == NornsInput.TOUCH_EVENT
end

function NornsInput.mk_press(x,y)
  return { type = NornsInput.PRESS_EVENT, x = x, y = y }
end

function NornsInput.is_press(event)
  return event.type == NornsInput.PRESS_EVENT
end

function NornsInput.mk_release(x,y)
  return { type = NornsInput.RELEASE_EVENT, x = x, y = y }
end

function NornsInput.is_release(event)
  return event.type == NornsInput.RELEASE_EVENT
end

function NornsInput.mk_tap(x,y)
  return { type = NornsInput.TAP_EVENT, x = x, y = y }
end

function NornsInput.is_tap(event)
  return event.type == NornsInput.TAP_EVENT
end

function NornsInput.mk_drag(x,y, start_x, start_y, last_x, last_y)
  return { type = NornsInput.DRAG_EVENT, x = x, y = y, start_x = start_x, start_y = start_y, last_x = last_x, last_y = last_y }
end

function NornsInput.is_drag(event)
  return event.type == NornsInput.DRAG_EVENT
end

function NornsInput.mk_redraw(beats)
  return { type = NornsInput.REDRAW_EVENT, beat = beats or clock.get_beats() }
end

function NornsInput.is_redraw(event)
  return event.type == NornsInput.REDRAW_EVENT
end

function NornsInput:on_key_event(n, z)
  if self.chain then self.chain:process(self.mk_key(n, z)) end
end

function NornsInput:on_enc_event(n, delta)
  if self.chain then self.chain:process(self.mk_enc(n, delta)) end
end

function NornsInput:on_touch_event(slot, press, x, y)
  if self.chain then self.chain:process(self.mk_touch(slot, press, x, y)) end
end

function NornsInput:on_press_event(x, y)
  if self.chain then self.chain:process(self.mk_press(x, y)) end
end

function NornsInput:on_release_event(x, y)
  if self.chain then self.chain:process(self.mk_release(x, y)) end
end

function NornsInput:on_tap_event(x, y)
  if self.chain then self.chain:process(self.mk_tap(x, y)) end
end

function NornsInput:on_drag_event(x, y, start_x, start_y, last_x, last_y)
  if self.chain then self.chain:process(self.mk_drag(x, y, start_x, start_y, last_x, last_y)) end
end


function NornsInput:on_redraw()
  if self.chain then self.chain:process(self.mk_redraw()) end
end

local function shared_input(props)
  if SingletonInput == nil then
    SingletonInput = NornsInput(props)
  end
  return SingletonInput
end

--
-- NornsDisplay
--
local NornsDisplay = sky.Device:extend()

local SingletonDisplay = nil

function NornsDisplay:new(props)
  NornsDisplay.super.new(self, props)
  for i, child in ipairs(props) do
    self[i] = child
  end
end

function NornsDisplay:process(event, output, state)
  -- FIXME: this really demands double buffering the screen. If each redraw pass
  -- assumed that the screen is cleared first then we have to clear the screen
  -- before we know if any of the children will render into it. Ideally we'd
  -- allow children to render into an offscreen buffer then swap it at the end
  -- if it was dirtied.
  if has_focus() and sky.is_type(event, NornsInput.REDRAW_EVENT) then
    local props = {}
    for i, child in ipairs(self) do
      if type(child) == 'function' then
        child()
      else
        props.position = i
        child:render(event, props)
      end
    end
  else
    output(event)
  end
end

local function shared_display(props)
  if SingletonDisplay == nil then
    SingletonDisplay = NornsDisplay(props)
  end
  return SingletonDisplay
end


return {
  NornsInput = shared_input,
  NornsDisplay = shared_display,

  -- low level drawing focus controls
  has_focus = has_focus,
  set_focus = set_focus,

  -- events
  mk_key = NornsInput.mk_key,
  mk_enc = NornsInput.mk_enc,
  mk_touch = NornsInput.mk_touch,
  mk_press = NornsInput.mk_press,
  mk_release = NornsInput.mk_release,
  mk_tap = NornsInput.mk_tap,
  mk_drag = NornsInput.mk_drag,
  mk_redraw = NornsInput.mk_redraw,

  is_key = NornsInput.is_key,
  is_enc = NornsInput.is_enc,
  is_touch = NornsInput.is_touch,
  is_press = NornsInput.is_press,
  is_release = NornsInput.is_release,
  is_tap = NornsInput.is_tap,
  is_drag = NornsInput.is_drag,
  is_redraw = NornsInput.is_redraw,

  KEY_EVENT = NornsInput.KEY_EVENT,
  ENC_EVENT = NornsInput.ENC_EVENT,
  TOUCH_EVENT = NornsInput.TOUCH_EVENT,
  PRESS_EVENT = NornsInput.PRESS_EVENT,
  RELEASE_EVENT = NornsInput.RELEASE_EVENT,
  TAP_EVENT = NornsInput.TAP_EVENT,
  DRAG_EVENT = NornsInput.DRAG_EVENT,
  REDRAW_EVENT = NornsInput.REDRAW_EVENT,
}




