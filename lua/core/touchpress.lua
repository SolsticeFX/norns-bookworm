--- touchscreens
-- @module touchtap
--TOATDO

local touchpress = {}

local util = require 'util'

local now = util.time()

touchpress.time = now
touchpress.callback = norns.none


touchpress.process = function(x,y)

screen.ping()
  end

return touchpress