--- touchscreens
-- @module touchscreens
--TOATDO

local touchscreen = {}

local util = require 'util'

local now = util.time()

touchscreen.deadzone = 50
_G.x = 0
_G.y = 0
_G.press = 0
_G.start_x = 0 
_G.start_y = 0 
_G.last_x = 0 
_G.last_y = 0 
_G.touch_resolution_x = 800
_G.touch_resolution_y = 480
touchscreen.time = now
touchscreen.callback = norns.none

touchscreen.process = function(slot, press, gx ,gy)
    touchscreen.callback(slot,press,gx,gy)
end
  

  return touchscreen 
