--- touchscreens
-- @module touchtap
--TOATDO

local touchdrag = {}

local util = require 'util'

local now = util.time()

touchdrag.callback = norns.none


touchdrag.process = function(gx ,gy, start_x, start_y, last_x, last_y)
  touchdrag.callback(gx ,gy, start_x, start_y, last_x, last_y)
end

return touchdrag