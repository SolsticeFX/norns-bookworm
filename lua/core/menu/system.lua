local m = {
  pos = 1,
  list = {"DEVICES", "WIFI", "MODS", "SETTINGS", "RESTART", "UPDATE", "LOG"},
  pages = {"DEVICES", "WIFI", "MODS", "SETTINGS", "RESTART", "UPDATE", "LOG"}
}

m.key = function(n,z)
  if n==2 and z==1 then
    _menu.set_page("HOME")
  elseif n==3 and z==1 then
    _menu.set_page(m.pages[m.pos])
  end
end

m.enc = function(n,delta)
  if n==2 then
    m.pos = util.clamp(m.pos + delta, 1, #m.list)
    _menu.redraw()
  end
end

m.redraw = function()
  screen.clear()
  for i=1,6 do
    if (i > 3 - m.pos) and (i < #m.list - m.pos + 4) then
      screen.move(0,10*i)
      local line = m.list[i+m.pos-3]
      if(i==3) then
        screen.rgblevel(15,0,0)
        screen.text(line)
        screen.rgblevel(0,15,0)
        screen.text(" >")



      else
        screen.level(4)
        screen.text(line)
      end
      


    end
  end
  screen.update()
end

m.init = norns.none
m.deinit = norns.none


return m
