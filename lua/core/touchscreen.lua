--- touchscreens
-- @module touchscreens
--TOATDO

local touchscreen = {}

local util = require 'util'

local now = util.time()

touchscreen.deadzone = 50
touchscreen.x = {0,0,0,0,0}
touchscreen.y = {0,0,0,0,0}
touchscreen.press = {0,0,0,0,0}
touchscreen.time = {now,now,now,now,now}


touchscreen.callback = norns.none

