local m = {
  confirmed = false
}

m.key = function(n,z)
  if n==2 and z==1 then
    _menu.set_page("SYSTEM")
  elseif n==3 and z==1 then
    --m.confirmed = true
    os.execute("python3 /home/we/leds.py "..(2^(norns.state.led_brightness/13)))
    _menu.redraw()
    --_norns.restart()
  end
end


m.enc = function(n,delta) 
  if n==3 then
    norns.state.led_brightness = util.clamp(norns.state.led_brightness + delta, 0, 100)
    C = 255
    --os.execute("python3 /home/we/leds.py "..(255 * math.log(norns.state.led_brightness*2.55/C + 1) / math.log(255/C + 1)))
    screen.update = screen.update_default
    _menu.redraw()
  end

end

m.redraw = function()
  screen.clear()
  screen.level(m.confirmed==false and 10 or 2)
  screen.move(64,20)
  screen.text_center("LED Brightness: ")
  screen.move(64,30)
  screen.text_center(norns.state.led_brightness)
  screen.update()
end

m.init = function() end
m.deinit = function() end

return m

