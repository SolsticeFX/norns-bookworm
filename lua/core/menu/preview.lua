local tab = require 'tabutil'

local m = {
  meta = {},
  scrollTicker = 0
}

m.init = function()
  m.wait = 0
  m.meta = norns.script.metadata(_menu.previewfile)
  m.len = tab.count(m.meta)
  m.state = 0
  m.pos = 0
  m.posmax = m.len - 8
  if m.posmax < 0 then m.posmax = 0 end
  scrollTicker = m.pos*(_G.touch_resolution_y/9)

end

m.deinit = norns.none

m.key = function(n,z)
  if n==3 and m.state == 1 then
    m.wait = 1
    _menu.redraw()
    norns.script.load(_menu.previewfile)
  elseif n ==3 and z == 1 then
    m.state = 1
  elseif n == 2 and z == 1 then
    _menu.set_page("SELECT")
  end
end

m.enc = function(n,d)
  if n==2 then
    m.pos = util.clamp(m.pos + d, 0, m.posmax)
    listTicker = m.pos*(_G.touch_resolution_y/9)
    _menu.redraw()
  end
end

m.drag = function(x,y,sx,sy,lx,ly) 
  scrollTicker = util.clamp((scrollTicker - y + ly),0,m.posmax*67.5)
  m.pos = util.clamp(math.floor(scrollTicker/67.5), 0, m.posmax)
  _menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.level(15)
  if m.wait == 0 then
    for i=1,8 do
      if i <= m.len then
        screen.move(0,i*8-2)
        screen.text(m.meta[i+m.pos])
      end
    end
  else
    screen.move(64,32)
    screen.text_center("loading...")
  end
  screen.update()
end

return m
