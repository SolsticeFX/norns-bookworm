--- touchscreens
-- @module touchtap
--TOATDO

local touchdrag = {}

local util = require 'util'

local now = util.time()

touchdrag.callback = norns.none


touchdrag.process = function(x,y,start_x,start_y,last_x,last_y)

screen.ping()
  end

return touchdrag