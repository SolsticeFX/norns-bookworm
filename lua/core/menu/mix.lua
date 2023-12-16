local m = {
  sel = 1
}

local scx = 128
local labels = {"output", "input", "monitor", "engine", "softcut", "tape"}
local paramslist = {"output_level", "input_level", "monitor_level", "engine_level", "softcut_level", "tape_level"}
local paramvals = {0,0,0,0,0,0}

local bigmarkerwidth = 10
local markerwidth = 4
local linesabove = 5
local linesbelow = 15







m.key = function(n,z)
  if n==2 and z==1 and m.sel > 1 then
    m.sel = m.sel - 1
  elseif n==3 and z==1 and m.sel < 3 then
    m.sel = m.sel + 1
  end
end

m.enc = function(n,d)
  local ch1 = {"output_level", "monitor_level", "softcut_level"}
  local ch2 = {"input_level", "engine_level", "tape_level"}

  if n==2 then
    params:delta(ch1[m.sel],d)
    --paramvals[2*(m.sel)-1] = (string.format("%." .. (2 or 0) .. "f", params:get(paramslist[2*(m.sel)-1])).." dB")
  elseif n==3 then
    params:delta(ch2[m.sel],d)
    --paramvals[2*(m.sel)] = (string.format("%." .. (2 or 0) .. "f", params:get(paramslist[2*(m.sel)])).." dB")
  end
  _menu.redraw()
end

m.drag = function(x,y,sx,sy,lx,ly)

local ssx = util.clamp(sx - 57, 1, 800) 
local ssy = util.clamp(y/7.5, 8.5, 42.5) 
local sssy = (ssy-8.5)/34
  --params:delta(paramslist[(math.ceil(ssx*7/800))],(ly-y)/7.5)
  params:set_raw(paramslist[(math.ceil(ssx*7/800))],(1-(sssy))*1.1)
  _menu.redraw()
end

m.tap = function (x,y)
local ssx = util.clamp(x - 57, 1, 800) 
local ssy = util.clamp(y/7.5, 8.5, 42.5) 
local sssy = (ssy-8.5)/34
  params:set_raw(paramslist[(math.ceil(ssx*7/800))],(1-(sssy))*1.1)
  _menu.redraw()
end


m.redraw = function()
  local n
  screen.clear()
  screen.aa(1)
  _menu.draw_panel()
  screen.line_width(0.5)
  --screen.font_face(4)


  screen.level(12)
  n = m.in1/64*48
  screen.rect(128*2/7 - 8,55.5,2,-n)
  screen.stroke()

  n = m.in2/64*48
  screen.rect(128*2/7 -10,55.5,2,-n)
  screen.stroke()

  n = m.out1/64*48
  screen.rect(128/7 -8 ,55.5,2,-n)
  screen.stroke()

  n = m.out2/64*48
  screen.rect(128/7 -10,55.5,2,-n)
  screen.stroke()


  for i=1,6 do
    local x = 128*i/7

    screen.level(6)
    for j=1,linesbelow do
      screen.move((x-markerwidth/2 ), (21.5 +(j*34/linesbelow)))
      screen.line_rel(markerwidth,0)
      screen.stroke()
    end

    for j=1,linesabove do
      screen.move((x-markerwidth/2), (21.5 -(j*34/linesbelow)))
      screen.line_rel(markerwidth,0)
      screen.stroke()
    end

    screen.level(15)
    screen.move(x-bigmarkerwidth/2 ,21.5)
    screen.line_rel(bigmarkerwidth,0)
    screen.stroke()
    
    screen.font_size(4)
    screen.move(x,63)
    screen.text_center(labels[i])
    screen.font_size(3)
    screen.move(x,69)
   screen.text_center((string.format("%." .. (2 or 0) .. "f", params:get(paramslist[i])).." dB"))
  end


  n = params:get_raw("output_level")*48
  --screen.rect(128/7,55.5,2,-n)
  screen.rgblevel(6,7,8)
  screen.rect(128/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()


  n = params:get_raw("input_level")*48
  screen.rgblevel(7,6,8)
  screen.rect(128*2/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()
  --screen.stroke()


  n = params:get_raw("monitor_level")*48
  screen.rgblevel(8,7,6)
  screen.rect(128*3/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()
  --screen.stroke()

  n = params:get_raw("engine_level")*48
  screen.rgblevel(7,8,6)
  screen.rect(128*4/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()

  n = params:get_raw("softcut_level")*48
  screen.rgblevel(6,8,7)
  screen.rect(128*5/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()

  n = params:get_raw("tape_level")*48
  screen.rgblevel(8,6,7)
  screen.rect(128*6/7-(bigmarkerwidth/2),55.5-n,10,5)
  screen.fill()
--

screen.level(15)
  screen.line_width(1)
  screen.font_size(8)
  screen.update()
end

m.init = function()
  _norns.vu = m.vu
  m.in1 = 0
  m.in2 = 0
  m.out1 = 0
  m.out2 = 0

  for i=1,6 do
  paramvals[i] = (string.format("%." .. (2 or 0) .. "f", params:get(paramslist[i])).." dB")
  
  end

  norns.encoders.set_accel(2,true)
  norns.encoders.set_sens(2,1)
  norns.encoders.set_sens(3,1)
end

m.deinit = function()
  norns.encoders.set_accel(2,false)
  norns.encoders.set_sens(2,2)
  norns.encoders.set_sens(3,2)
  _norns.vu = norns.none
end

m.vu = function(in1,in2,out1,out2)
  m.in1 = in1
  m.in2 = in2
  m.out1 = out1
  m.out2 = out2
  _menu.redraw()
end

return m
