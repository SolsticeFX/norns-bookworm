-- menu.lua
-- norns screen-based navigation module

local tab = require 'tabutil'
local util = require 'util'
local fileselect = require 'fileselect'
local listselect = require 'listselect'
local textentry = require 'textentry'
local gamepad = require 'gamepad'

_menu = {}

-- global functions for scripts
key = norns.none
enc = norns.none
pedalenc = norns.none
touch = norns.none
press = norns.none
release = norns.none
tap = norns.none
drag = norns.none
redraw = norns.blank
cleanup = norns.none

-- tuning
local KEY1_HOLD_TIME = 0.25

_menu.mode = false
_menu.paramMode = false
_menu.page = "HOME"
_menu.panel = 3
--_menu.panels = {"MIX", "TAPE", "HOME", "LOOPER", "PARAMS"}
_menu.panels = {"MIX", "TAPE", "HOME", "PARAMS"}
_menu.alt = false
_menu.scripterror = false
_menu.locked = false
_menu.errormsg = ""
_menu.shownav = false
_menu.showstats = false
_menu.previewfile = ""

-- menu pages
local m = {}
_menu.m = m

-- METROS
local pending = false
-- metro for key hold detection
local metro = require 'core/metro'
local t = metro[31]
t.time = KEY1_HOLD_TIME
t.count = 1
t.event = function(_)
  _menu.key(1,1)
  pending = false
  if _menu.mode == true then _menu.redraw() end
  if _menu.paramMode == true then _menu.redraw() end
end
-- metro for page status updates
_menu.timer = metro[32]
-- metro for nav vanish
local nav_vanish = metro[35]
nav_vanish.time = 1
nav_vanish.event = function()
  _menu.shownav = false
  if _menu.mode == true then _menu.redraw() end
  if _menu.paramMode == true then _menu.redraw() end
  nav_vanish:stop()
end
-- screen.lua has metro[35] for screensaver

-- FIXME: get rid of norns.menu -- just put stuff in _menu
-- assigns key/enc/screen handlers after user script has loaded
norns.menu = {}
norns.menu.init = function() _menu.set_mode(_menu.mode) end -- used by fileselect.lua
norns.menu.status = function() return _menu.mode end
norns.menu.set = function(new_enc, new_pedalenc, new_key, new_redraw, new_touch, new_press, new_release, new_tap, new_drag)
  _menu.penc = new_enc
  _menu.pedalpenc = new_pedalenc
  _menu.key = new_key
  _menu.redraw = new_redraw
  _menu.ptouch = new_touch
  _menu.ppress = new_press
  _menu.prelease = new_release
  _menu.ptap = new_tap
  _menu.pdrag = new_drag
end
norns.menu.get_enc = function() return _menu.penc end
norns.menu.get_pedalenc = function() return _menu.pedalpenc end
norns.menu.get_key = function() return _menu.key end
norns.menu.get_touch = function() return _menu.ptouch end
norns.menu.get_press = function() return _menu.ppress end
norns.menu.get_release = function() return _menu.prelease end
norns.menu.get_tap = function() return _menu.ptap end
norns.menu.get_drag = function() return _menu.pdrag end
norns.menu.get_redraw = function() return _menu.redraw end
norns.menu.toggle = function(status) _menu.set_mode(status) end

norns.scripterror = function(msg)
  if msg == nil then msg = "" end
  print("### SCRIPT ERROR: "..msg)
  if util.string_starts(msg,"missing") then
    print("### try 'SYSTEM > RESTART'")
  elseif util.string_starts(msg,"version") then
    print("### try 'SYSTEM > UPDATE'")
    print("### or check for new disk image")
  end
  _menu.errormsg = msg
  _menu.scripterror = true
  _menu.locked = true
  _menu.set_page("HOME")
  _menu.set_mode(true)
end

norns.init_done = function(status)
  _menu.set_page("HOME")
  _menu.set_mode(true)
  _menu.panel = 3
  if status == true then
    _menu.scripterror = false
    m["PARAMS"].pos = 0
    _menu.locked = false
    _menu.set_mode(false)
  end
  m["PARAMS"].reset()
end




-- input redirection
--TODO: redo with new UI widgets

_menu.drag = function(gx,gy,start_x,start_y,last_x,last_y)

if(start_y<40) and (_menu.mode or _menu.paramMode) then

  local c = util.clamp(math.floor(gx/200)+1,1,4)
  if c ~= _menu.panel then
    _menu.panel = c
    _menu.set_page(_menu.panels[_menu.panel])
  end

else _menu.pdrag(gx,gy,start_x,start_y,last_x,last_y) end

end

_menu.press = function(gx,gy) 

  _menu.ppress(gx,gy) 
 
end




_menu.release = function(gx,gy) 

   _menu.prelease(gx,gy) 
  
end

_menu.tap = function( gx, gy)

    if(gy<40) and (_menu.mode or _menu.paramMode) then
      local c = util.clamp(math.floor(gx/200)+1,1,4)
      if c ~= _menu.panel then
        _menu.panel = c
        _menu.set_page(_menu.panels[c])
      end

    else 
     _menu.ptap(gx,gy) 
     

     
    end
  end

_menu.enc = function(n, delta)
  if n==1 and _menu.alt == false and (_menu.mode or _menu.paramMode) then
    --mix:delta("output",delta)
    local c = util.clamp(_menu.panel+delta,1,4)
    if c ~= _menu.panel then
      _menu.shownav = true
      _menu.panel = c
      _menu.set_page(_menu.panels[_menu.panel])
      nav_vanish:start()
    end
  else _menu.penc(n, delta) 
  end
end

_menu.pedalenc = function(n, delta)
  if n==1 and _menu.alt == false and (_menu.mode or _menu.paramMode) then
    --mix:delta("output",delta)
    local c = util.clamp(_menu.panel+delta,1,4)
    if c ~= _menu.panel then
      _menu.shownav = true
      _menu.panel = c
      _menu.set_page(_menu.panels[_menu.panel])
      nav_vanish:start()
    end
  else _menu.pedalpenc(n, delta) 
  end
end


_norns.key = function(n, z)
  -- key 1 detect for short press
  if n == 1 then
    if z == 1 then
      _menu.alt = true
      pending = true
      t:start()
    elseif z == 0 and pending == true then
      _menu.alt = false
      if _menu.mode and _menu.locked == false then
        _menu.set_mode(false)
      else _menu.set_mode(true) end
      t:stop()
      pending = false
    elseif z == 0 then
      _menu.alt = false
      _menu.key(n,z) -- always 1,0
      if _menu.mode == true then _menu.redraw() end
    else
      _menu.key(n,z) -- always 1,1
    end
  elseif n == 4 then
    if z == 1 then
      _menu.alt = true
      pending = true
      t:start()
    elseif z == 0 and pending then
      _menu.alt = false
      if _menu.paramMode and _menu.locked == false then
        _menu.set_param_mode(false)
      else _menu.set_param_mode(true) end
      t:stop()
      pending = false
    elseif z == 0 then
      _menu.alt = false
      _menu.key(n,z) -- always 1,0
      if _menu.paramMode then _menu.redraw() end
    else
      _menu.key(n,z) -- always 1,1
    end
  else
    _menu.key(n,z)
  end
  screen.ping()
end

-- _menu.set mode
_menu.set_mode = function(mode)
  if mode == false then -- ACTIVATE PLAY MODE
    if _menu.mode == true then _norns.screen_restore() end
    _menu.mode = false
    m[_menu.page].deinit()
    screen.clear()
    screen.update()
    redraw = norns.script.redraw
    _menu.key = key
    norns.encoders.callback = enc
    norns.pedalencoders.callback = pedalenc
    norns.touchpress.callback = press
    norns.touchtap.callback = tap
    norns.touchdrag.callback = drag
    norns.touchrelease.callback = release
  
    norns.pedalenc.resume()
    norns.enc.resume()
    redraw()
  elseif mode == true then -- ACTIVATE MENu MODE
    if _menu.mode == false then _norns.screen_save() end
    _menu.mode = true
    _menu.paramMode = false
    _menu.alt = false
    redraw = norns.none
    screen.font_face(1)
    screen.font_size(8)
    screen.line_width(1)
    norns.encoders.callback = _menu.enc
    norns.pedalencoders.callback = _menu.pedalenc
    norns.touchtap.callback = _menu.tap
    norns.touchdrag.callback = _menu.drag
    norns.touchrelease.callback = _menu.release
    norns.touchpress.callback = _menu.press

    norns.pedalencoders.set_accel(1,true)
    norns.pedalencoders.set_sens(1,1)
    norns.pedalencoders.set_accel(2,true)
    norns.pedalencoders.set_sens(2,1)
    norns.pedalencoders.set_accel(3,true)
    norns.pedalencoders.set_sens(3,1)
    
    norns.encoders.set_accel(1,false)
    norns.encoders.set_sens(1,2)
    norns.encoders.set_accel(2,false)
    norns.encoders.set_sens(2,2)
    norns.encoders.set_accel(3,true)
    norns.encoders.set_sens(3,2)
    _menu.panel = 3
    _menu.set_page(_menu.panels[_menu.panel])
  end
end

_menu.set_param_mode = function(mode)
  if paramMode == false then -- ACTIVATE PLAY MODE
    if _menu.paramMode == true then _norns.screen_restore() end
    _menu.paramMode = false
    m[_menu.page].deinit()
    screen.clear()
    screen.update()
    redraw = norns.script.redraw
    _menu.key = key
    norns.encoders.callback = enc
    norns.pedalencoders.callback = pedalenc
    norns.touchpress.callback = press
    norns.touchtap.callback = tap
    norns.touchdrag.callback = drag
    norns.touchrelease.callback = release
    norns.pedalenc.resume()
    norns.enc.resume()
    redraw()
  elseif mode == true then -- ACTIVATE PARAM MODE
    if _menu.paramMode == false then _norns.screen_save() end
    _menu.paramMode = true
    _menu.mode = false
    _menu.alt = false
    redraw = norns.none
    screen.font_face(1)
    screen.font_size(8)
    screen.line_width(1)
    norns.encoders.callback = _menu.enc
    norns.pedalencoders.callback = _menu.pedalenc
    norns.touchtap.callback = _menu.tap
    norns.touchdrag.callback = _menu.drag
    norns.touchrelease.callback = _menu.release
    norns.touchpress.callback = _menu.press 
    norns.pedalencoders.set_accel(1,false)
    norns.pedalencoders.set_sens(1,2)
    norns.pedalencoders.set_accel(2,false)
    norns.pedalencoders.set_sens(2,2)
    norns.pedalencoders.set_accel(3,true)
    norns.pedalencoders.set_sens(3,2)   
    norns.encoders.set_accel(1,false)
    norns.encoders.set_sens(1,2)
    norns.encoders.set_accel(2,false)
    norns.encoders.set_sens(2,2)
    norns.encoders.set_accel(3,true)
    norns.encoders.set_sens(3,2)
    _menu.panel = 4
    _menu.set_page(_menu.panels[_menu.panel])
  end
end




-- set page
_menu.set_page = function(page)
  m[_menu.page].deinit()
  _menu.page = page
  _menu.key = m[page].key
  _menu.penc = m[page].enc
  _menu.pedalpenc = m[page].pedalenc
  _menu.redraw = m[page].redraw
  _menu.ptouch = m[page].touch
  _menu.ppress = m[page].press
  _menu.prelease = m[page].release
  _menu.ptap = m[page].tap
  _menu.pdrag = m[page].drag
  _menu.keyboardcode = m[page].keycode
  _menu.keyboardchar = m[page].keychar
  _menu.custom_gamepad_axis = m[page].gamepad_axis
  _menu.custom_gamepad_dpad = m[page].gamepad_dpad
  _menu.custom_gamepad_button = m[page].gamepad_button
  _menu.custom_gamepad_analog = m[page].gamepad_analog
  m[page].init()
  _menu.redraw()
end

-- draw panel indicator
function _menu.draw_panel()
  --if _menu.shownav then
    screen.aa(1)
    screen.line_width(4)
    for i = 1,4 do
      screen.rgblevel(i == _menu.panel and 15 or 7,i == _menu.panel and 13 or 5,i == _menu.panel and 5 or 2)
      screen.move((i-1)*33,0)
      screen.line_rel(30,0)
      screen.stroke()
    end
    screen.line_width(1)

  --end
end

-- global menu keys
function _menu.keycode(c,value)
  -- those are globals and can't be overriden by a sub-menu
  if value>0 then
    if c=="F1" then
      _menu.set_page("MIX")
      return
    elseif c=="F2" then
      _menu.set_page("TAPE")
      return
    elseif c=="F3" then
      _menu.set_page("HOME")
      return
    elseif c=="F4" then
      _menu.set_page("PARAMS")
      return
    end
  end

  -- if a sub-menu defines its own handler, it takes precedence...
  if _menu.keyboardcode then
    _menu.keyboardcode(c,value)
    return
  end

  -- ... otherwise we use those default bindings in most places

  -- E2 emu (scolling)
  if value>0 then
    if c=="DOWN" then
      _menu.penc(2,1)
    elseif c=="UP" then
      _menu.penc(2,-1)
    elseif c=="PAGEDOWN" then
      _menu.penc(2,6)
    elseif c=="PAGEUP" then
      _menu.penc(2,-6)
    end
  end

  -- K2/K3 emu
  if value==1 or value==0 then
    if c=="LEFT" then
      _menu.key(2,value)
    elseif c=="RIGHT" then
      _menu.key(3,value)
    end
  end

  -- parameter change with +/-
  if c=="MINUS" then
    _menu.penc(3,value*-1)
  elseif c=="EQUAL" then
    _menu.penc(3,value)
  end
end

function _menu.keychar(c)
  if _menu.keyboardchar then _menu.keyboardchar(c) end
end

function _menu.gamepad_axis(_sensor_axis,_value)

  -- if a sub-menu defines its own handler, it takes precedence...
  if _menu.custom_gamepad_axis then
    _menu.custom_gamepad_axis(_sensor_axis,_value)
    return
  end

  if gamepad.down() then
    _menu.penc(2,1)
  elseif gamepad.up() then
    _menu.penc(2,-1)
  elseif gamepad.left() then
    _menu.key(2,1)
  elseif gamepad.right() then
    _menu.key(3,1)
  end
end

function _menu.gamepad_button(b,value)

  if value == 1 and (b == "L1" or b == "R1") then
    local delta = b == "R1" and 1 or -1
    local c = util.clamp(_menu.panel+delta,1,4)
    if c ~= _menu.panel then
      _menu.shownav = true
      _menu.panel = c
      _menu.set_page(_menu.panels[_menu.panel])
      nav_vanish:start()
    end
  end

  -- if a sub-menu defines its own handler, it takes precedence...
  if _menu.custom_gamepad_button then
    _menu.custom_gamepad_button(b,value)
    return
  end

  if value==1 or value==0 then
    if b == "B" then
      _menu.key(2,value)
    elseif b == "A" then
      _menu.key(3,value)
    end
  end
end

-- interfaces

m["HOME"] = require 'core/menu/home'
--m["LOOPER"] = require '/home/we/dust/code/reels/reels'
m["SELECT"] = require 'core/menu/select'
m["PREVIEW"] = require 'core/menu/preview'
m["PARAMS"] = require 'core/menu/params'
m["SYSTEM"] = require 'core/menu/system'
m["ABOUT"] = require 'core/menu/about'
m["LED"] = require 'core/menu/led'
m["DEVICES"] = require 'core/menu/devices'
m["WIFI"] = require 'core/menu/wifi'
m["SETTINGS"] = require 'core/menu/settings'
m["RESTART"] = require 'core/menu/restart'
m["RESET"] = require 'core/menu/reset'
m["UPDATE"] = require 'core/menu/update'
m["SHUTDOWN"] = require 'core/menu/shutdown'
m["SLEEP"] = require 'core/menu/sleep'
m["MIX"] = require 'core/menu/mix'
m["TAPE"] = require 'core/menu/tape'
m["MODS"] = require 'core/menu/mods'
m["LOG"] = require 'core/menu/log'
