--- touchscreens
-- @module touchtap
--TOATDO

local touchtap = {}

local util = require 'util'

local now = util.time()

touchtap.callback = norns.none



touchtap.process = function(gx,gy)
  now = util.time()
    touchtap.callback(gx,gy)
    screen.ping()
end

norns.tap = {}
return touchtap

