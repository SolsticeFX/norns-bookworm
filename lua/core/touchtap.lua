--- touchscreens
-- @module touchtap
--TOATDO

local touchtap = {}

local util = require 'util'

local now = util.time()

touchtap.callback = norns.none

touchtap.process = function(gx ,gy)
  touchtap.callback(gx,gy)
end

return touchtap

