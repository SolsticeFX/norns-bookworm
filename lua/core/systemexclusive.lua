--- encoders
-- @module encoders

local systemexclusive = {}

local util = require 'util'

local now = util.time()

--- process delta
systemexclusive.process = function(id, data, size)
midi.to_msg(data)
end



norns.sysex = {}


norns.sysex.resume = function()
  --for n=1,4 do
    --norns.encoders.set_accel(n,accel[n])
    --norns.encoders.set_sens(n,sens[n])
  --end
end


return systemexclusive
