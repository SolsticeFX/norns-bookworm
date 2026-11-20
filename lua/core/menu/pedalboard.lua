local textentry= require 'textentry'
local m = {
  pos = 1,
  list = {"DEBUG", "UART MIDI", "USB MIDI", "BT MIDI", "WIFI MONITOR", "WIFI MIDI", "OTA"},
  pages = {}
}

m.key = function(n,z)
 if n==3 and z==1 then
  os.execute("python3 /home/we/norns/scripts/peripheralconfig.py "..(string.format("%06X", norns.state.pedalboard_debug)).. " "..(string.format("%06X", norns.state.pedalboard_uart)).." "..(string.format("%06X", norns.state.pedalboard_usb)).." "..(string.format("%06X", norns.state.pedalboard_bt))..(string.format("%06X", norns.state.pedalboard_wifimidi))..(string.format("%06X", norns.state.pedalboard_wifimonitor))..(string.format("%06X", norns.state.pedalboard_ota)))

end
end

m.enc = function(n,delta)
  if n==2 then
    m.pos = util.clamp(m.pos + delta, 1, #m.list)
    _menu.redraw()
    
  elseif n==3 then 
   if m.list[m.pos]=="DEBUG" then
    norns.state.pedalboard_debug = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
   elseif m.list[m.pos]=="UART MIDI" then
    norns.state.pedalboard_uart = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()

  elseif m.list[m.pos]=="USB MIDI" then
    norns.state.pedalboard_usb = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
  elseif m.list[m.pos]=="BT MIDI" then
    norns.state.pedalboard_bt = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
  elseif m.list[m.pos]=="WIFI MIDI" then
    norns.state.pedalboard_wifimidi = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
  elseif m.list[m.pos]=="WIFI MONITOR" then
    norns.state.pedalboard_wifimonitor = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
  elseif m.list[m.pos]=="OTA" then
    norns.state.pedalboard_ota = (delta>0) and 1 or 0
    screen.update = screen.update_default
    _menu.redraw()
  end
  end
end

m.redraw = function()
  screen.clear()
  for i=1,6 do
    if (i > 3 - m.pos) and (i < #m.list - m.pos + 4) then
      screen.move(0,10*i)
      local line = m.list[i+m.pos-3]
      if(i==3) then
        screen.level(15)
      else
        screen.level(4)
      end
      screen.text(line)
      if m.list[i+m.pos-3]=="DEBUG" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_debug==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="UART MIDI" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_uart==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="USB MIDI" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_usb==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="BT MIDI" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_bt==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="WIFI MIDI" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_wifimidi==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="WIFI MONITOR" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_wifimonitor==1 and "on" or "off")
      elseif m.list[i+m.pos-3]=="OTA" then
	      screen.move(128,10*i)
	      screen.text_right(norns.state.pedalboard_ota==1 and "on" or "off")
      end

    end
  end
  screen.update()
end

m.init = norns.none
m.deinit = norns.none


return m
