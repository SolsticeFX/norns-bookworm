--- encoders
-- @module encoders

local encoders = {}

local util = require 'util'

local now = util.time()
encoders.tick = {0,0,0,0}
encoders.accel = {true,true,true,true}
encoders.sens = {1,1,1,1}
encoders.time = {now,now,now,now}
encoders.colors = {0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF}
encoders.callback = norns.none

encoders.load_colors = function()
encoders.colors = norns.state.ui_colors
end

encoders.save_colors = function()
norns.state.ui_colors = norns.encoders.colors
end

encoders.update_color = function(n, col)
  encoders.colors[n] = col
  encoders.set_rgb(0)
end


encoders.set_rgb = function(n)
  if n == 0 then
    os.execute("python3 /home/we/color1.py "..(string.format("%06X", encoders.colors[1])).. " "..(string.format("%06X", encoders.colors[2])).." "..(string.format("%06X", encoders.colors[3])).." "..(string.format("%06X", encoders.colors[4])))

    print(string.format("%06X", encoders.colors[1]))
    print(string.format("%06X", encoders.colors[2]))
    print(string.format("%06X", encoders.colors[3]))
    print(string.format("%06X", encoders.colors[4]))


  elseif n == 1 then
    os.execute("python3 /home/we/color1.py "..(norns.state.ui_colors[1]).. " "..(norns.state.ui_colors[2]).." "..(norns.state.ui_colors[3]).." "..(norns.state.ui_colors[4]))
  elseif n == 2 then
    screen.rgblevel(15,0,0)
  elseif n == 3 then
    screen.rgblevel(0,15,0)
  elseif n == 4 then
    screen.rgblevel(0,0,15)
end
end

encoders.set_inactive_rgb = function(n)
  if n == 0 then
    screen.rgblevel(3,3,3)
  elseif n == 1 then
    screen.rgblevel(3,3,0)
  elseif n == 2 then
    screen.rgblevel(3,0,0)
  elseif n == 3 then
    screen.rgblevel(0,3,0)
  elseif n == 4 then
    screen.rgblevel(0,0,3)
  else
    screen.rgblevel(5,5,5)
end
end

encoders.get_active_color = function(n)
  if n > 0 then
    return encoders.colors[n]
  else
    return 0xFFFFFF
  end
end


fadedColor = function(activeHex)
  fade = 0xAA --vs 0xFF             
  r = activeHex >> 16                    
  g = (activeHex & 0xFF00) >> 8         
  b = (activeHex & 0xFF)     
  return ((r-r*fade//0x100) << 16) + ((g-g*fade//0x100) << 8) + (b-b*fade//0x100)
end



encoders.get_inactive_color = function(n)
  activeHex = encoders.colors[n]
  if n > 0 then
    return fadedColor(activeHex)
  else
    return 0x666666
  end
end


--- set acceleration
encoders.set_accel = function(n,z)
  if n == 0 then
    for k=1,4 do
      encoders.accel[k] = z
      encoders.tick[k] = 0
    end
  else
    encoders.accel[n] = z
    encoders.tick[n] = 0
  end
end

--- set sensitivity
encoders.set_sens = function(n,s)
  if n == 0 then
    for k=1,4 do
      encoders.sens[k] = util.clamp(s,1,16)
      encoders.tick[k] = 0
    end
  else
    encoders.sens[n] = util.clamp(s,1,16)
    encoders.tick[n] = 0
  end
end

--- process delta
encoders.process = function(n,d)
  now = util.time()
  local diff = now - encoders.time[n]
  encoders.time[n] = now

  if encoders.accel[n] then
    if diff < 0.005 then d = d*6
    elseif diff < 0.01 then d = d*4
    elseif diff < 0.02 then d = d*3
    elseif diff < 0.03 then d = d*2
    end
  end

  encoders.tick[n] = encoders.tick[n] + d

  if math.abs(encoders.tick[n]) >= encoders.sens[n] then
    local val = math.floor(encoders.tick[n] / encoders.sens[n])
    encoders.callback(n,val)
    encoders.tick[n] = 0
    screen.ping()
  end
end


-- script state

local accel = {true,true,true,true}
local sens = {2,2,2,2}

norns.enc = {}
norns.enc.accel = function(n,z)
  if n == 0 then
    for k=1,4 do
      accel[k] = z
    end
  else
    accel[n] = z
  end
  if(_menu.mode == false) then norns.encoders.set_accel(n,z) end
end

norns.enc.sens = function(n,s)
  if n == 0 then
    for k=1,4 do
      sens[k] = util.clamp(s,1,16)
    end
  else
    sens[n] = util.clamp(s,1,16)
  end
  if(_menu.mode == false) then norns.encoders.set_sens(n,s) end
end

norns.enc.resume = function()
  for n=1,4 do
    norns.encoders.set_accel(n,accel[n])
    norns.encoders.set_sens(n,sens[n])
  end
end


return encoders
