--- pedalencoders
-- @module pedalencoders

local pedalencoders = {}

local util = require 'util'

local now = util.time()
pedalencoders.tick = {0,0,0,0,0,0,0,0,0,0}
pedalencoders.accel = {true,true,true,true,true,true,true,true,true,true}
pedalencoders.sens = {1,1,1,1,1,1,1,1,1,1}
pedalencoders.time = {now,now,now,now,now,now,now,now,now,now}
pedalencoders.colors = {0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF,0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF,0xFFFF11, 0xFF1122}
pedalencoders.callback = norns.none

pedalencoders.load_colors = function()
pedalencoders.colors = norns.state.pedalboard_colors
end

pedalencoders.save_colors = function()
norns.state.pedalboard_colors = norns.pedalencoders.colors
end

pedalencoders.update_color = function(n, col)
  pedalencoders.colors[n] = col
  pedalencoders.set_rgb(0)
end


pedalencoders.set_rgb = function(n)
  if n == 0 then
    os.execute("python3 /home/we/color1.py "..(string.format("%06X", pedalencoders.colors[1])).. " "..(string.format("%06X", pedalencoders.colors[2])).." "..(string.format("%06X", pedalencoders.colors[3])).." "..(string.format("%06X", pedalencoders.colors[4])))
   

  elseif n == 1 then
    _norns.midi_send(midi.devices[1].dev, {0xf0,0x01,0xff,0xff,0x01,0xf7}) --sending any sysex message currently sends "boot" to esp UART
  elseif n == 2 then
    _norns.midi_send(midi.devices[1].dev, {0xf0,0x02,0xff,0x01,0x01,0xf7}) --sending any sysex message currently sends "boot" to esp UART
  elseif n == 3 then
    _norns.midi_send(midi.devices[1].dev, {0xf0,0x03,0xff,0x01,0x01,0xf7}) --sending any sysex message currently sends "boot" to esp UART
  elseif n == 4 then
    _norns.midi_send(midi.devices[1].dev, {0xf0,0x04,0xff,0x01,0x01,0xf7}) --sending any sysex message currently sends "boot" to esp UART
end
end


pedalencoders.set_pedalboard_rgb = function(n)
  if n == 0 then

    _norns.midi_send(midi.devices[1].dev, {0xf0,0x69,0xf7}) --sending any sysex message currently sends "boot" to esp UART
    
    os.execute("python3 /home/we/color1.py "..(string.format("%06X", pedalencoders.colors[1])).. " "..(string.format("%06X", pedalencoders.colors[2])).." "..(string.format("%06X", pedalencoders.colors[3])).." "..(string.format("%06X", pedalencoders.colors[4])))

    print(string.format("%06X", pedalencoders.colors[1]))
    print(string.format("%06X", pedalencoders.colors[2]))
    print(string.format("%06X", pedalencoders.colors[3]))
    print(string.format("%06X", pedalencoders.colors[4]))
    print(string.format("%06X", pedalencoders.colors[5]))
    print(string.format("%06X", pedalencoders.colors[6]))
    print(string.format("%06X", pedalencoders.colors[7]))
    print(string.format("%06X", pedalencoders.colors[8]))
    print(string.format("%06X", pedalencoders.colors[9]))
    print(string.format("%06X", pedalencoders.colors[10]))


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

pedalencoders.set_inactive_rgb = function(n)
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

pedalencoders.get_active_color = function(n)
  if n > 0 then
    return pedalencoders.colors[n]
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



pedalencoders.get_inactive_color = function(n)
  activeHex = pedalencoders.colors[n]
  if n > 0 then
    return fadedColor(activeHex)
  else
    return 0x666666
  end
end


--- set acceleration
pedalencoders.set_accel = function(n,z)
  if n == 0 then
    for k=1,10 do
      pedalencoders.accel[k] = z
      pedalencoders.tick[k] = 0
    end
  else
    pedalencoders.accel[n] = z
    pedalencoders.tick[n] = 0
  end
end

--- set sensitivity
pedalencoders.set_sens = function(n,s)
  if n == 0 then
    for k=1,10 do
      pedalencoders.sens[k] = util.clamp(s,1,16)
      pedalencoders.tick[k] = 0
    end
  else
    pedalencoders.sens[n] = util.clamp(s,1,16)
    pedalencoders.tick[n] = 0
  end
end

--- process delta
pedalencoders.process = function(n,d)
  now = util.time()
  local diff = now - pedalencoders.time[n]
  pedalencoders.time[n] = now

  if pedalencoders.accel[n] then
    if diff < 0.005 then d = d*6
    elseif diff < 0.01 then d = d*4
    elseif diff < 0.02 then d = d*3
    elseif diff < 0.03 then d = d*2
    end
  end

  pedalencoders.tick[n] = pedalencoders.tick[n] + d

  if math.abs(pedalencoders.tick[n]) >= pedalencoders.sens[n] then
    local val = math.floor(pedalencoders.tick[n] / pedalencoders.sens[n])
    if n <= 4 then
      --_norns.enc(n,val)
      norns.encoders.callback(n,val)
    else
      norns.encoders.callback(n,val)
      --_norns.enc(n,val)
    end

    pedalencoders.tick[n] = 0
    screen.ping()
  end
end


-- script state

local accel = {true,true,true,true,true,true,true,true,true,true}
local sens = {1,1,1,1,1,1,1,1,1,1}

norns.pedalenc = {}
norns.pedalenc.accel = function(n,z)
  if n == 0 then
    for k=1,10 do
      accel[k] = z
    end
  else
    accel[n] = z
  end
  if(_menu.mode == false) then norns.pedalencoders.set_accel(n,z) end
end

norns.pedalenc.sens = function(n,s)
  if n == 0 then
    for k=1,10 do
      sens[k] = util.clamp(s,1,16)
    end
  else
    sens[n] = util.clamp(s,1,16)
  end
  if(_menu.mode == false) then norns.pedalencoders.set_sens(n,s) end
end

norns.pedalenc.resume = function()
  for n=1,10 do
    norns.pedalencoders.set_accel(n,accel[n])
    norns.pedalencoders.set_sens(n,sens[n])
  end
end


return pedalencoders
