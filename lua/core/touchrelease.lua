--- touchscreens
-- @module touchtap
--TOATDO

local touchrelease = {}

local util = require 'util'

local now = util.time()

touchrelease.callback = norns.none

touchrelease.process = function(gx ,gy)
  touchrelease.callback(gx,gy)
end



return touchrelease