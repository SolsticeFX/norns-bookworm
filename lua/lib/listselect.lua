--- listselect utility
-- @module lib.listselect
-- reroutes redraw/enc/key

local ls = {}

function ls.enter(list, callback)
  ls.list = list
  ls.pos = 0
  ls.callback = callback
  ls.done = false
  ls.selection = nil

  ls.len = tab.count(ls.list)

  if norns.menu.status() == false then
    ls.key_restore = key
    ls.enc_restore = enc
    ls.redraw_restore = redraw
    key = ls.key
    enc = ls.enc
    redraw = norns.none
    norns.menu.init()
  else
    ls.menu_restore = norns.menu.save()
    norns.menu.set(ls.enc, ls.enc, ls.key, ls.redraw, nil, nil, nil, ls.tap, ls.drag)
  end
  ls.redraw()
end

function ls.exit()
  if norns.menu.status() == false then
    key = ls.key_restore
    enc = ls.enc_restore
    redraw = ls.redraw_restore
    norns.menu.init()
  else
    norns.menu.restore(ls.menu_restore)
  end
  if ls.selection then ls.callback(ls.selection)
  else ls.callback("cancel") end
end


ls.key = function(n,z)
  -- back
  if n==2 and z==1 then
    ls.done = true
  -- select
  elseif n==3 and z==1 then
    ls.selection = ls.list[ls.pos+1]
    ls.done = true
  elseif z == 0 and ls.done == true then
    ls.exit()
  end
end

ls.enc = function(n,d)
  if n==2 then
    ls.pos = util.clamp(ls.pos + d, 0, ls.len - 1)
    ls.redraw()
  end
end


-- touch (800x480 panel over the 128x64 screen): tap a row to pick it,
-- drag vertically to scroll
ls.tap = function(x, y)
  if ls.len == 0 then return end
  local sy = y * 80 / (_G.touch_resolution_y or 480) -- panel shows 128x80
  local row = math.floor((sy + 7) / 10)          -- rows have baselines at 10*i
  local idx = ls.pos + (row - 3)                 -- row 3 is the highlighted one
  if row < 1 or row > 6 or idx < 0 or idx > ls.len - 1 then return end
  ls.pos = idx
  ls.selection = ls.list[ls.pos + 1]
  ls.exit()
end

ls.drag = function(x, y, sx, sy, lx, ly)
  ls.drag_acc = (ls.drag_acc or 0) + (ly - y)
  local step = (_G.touch_resolution_y or 480) / 8
  while math.abs(ls.drag_acc) >= step do
    local d = ls.drag_acc > 0 and 1 or -1
    ls.drag_acc = ls.drag_acc - d * step
    ls.pos = util.clamp(ls.pos + d, 0, ls.len - 1)
  end
  ls.redraw()
end

ls.redraw = function()
  local i
  screen.clear()
  screen.move(0,10)
  screen.level(15)
  screen.font_face(1)
  screen.font_size(8)
  if ls.len > 0 then
    for i=1,6 do
      if (i > 2 - ls.pos) and (i < ls.len - ls.pos + 3) then
        screen.move(0,10*i)
        local line = ls.list[i+ls.pos-2]
        -- rows are scrolled by E2: draw them in E2's colour
        if norns.encoders and norns.encoders.screen_color then
          norns.encoders.screen_color(2, i==3)
        else
          screen.level(i==3 and 15 or 4)
        end
        --screen.text(string.upper(line))
        screen.text(line)
      end
    end
  else
    screen.move(0,40)
    screen.level(4)
    screen.text("none")
  end
  screen.update()
end

return ls
