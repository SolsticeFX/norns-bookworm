TouchUI = require("touchui")


function confirm()
  print("poop")
   _menu.redraw()
  _norns.restart()
end

function cancel()
  _menu.set_page("HOME")
end


confirmbutton = TouchUI.Button.new(79,79, 70, 20, 10 , "Yes", 3, confirm)
cancelbutton = TouchUI.Button.new(49,49, 70, 20, 10 , "No", 2, cancel)

local m = {
  confirmed = false
}

m.key = function(n,z)
  if n==2 and z==1 then
    _menu.set_page("HOME")
  elseif n==3 and z==1 then
    m.confirmed = true
    _menu.redraw()
    _norns.restart()
  end
end


m.enc = function(n,delta) end

m.tap = function(x,y)
 -- print(x,y)
 -- TouchUI.Button:tap(x,y)
  --TouchUI.Button:release(x,y)

  --print(x,y)
  if x >= 400 then
    m.confirmed = true
    confirmbutton.pressed=true
    confirmbutton:redraw()
    _menu.redraw()
    _norns.restart()
  else
   _menu.set_page("HOME")
  end
  _menu.redraw()
end

m.press = function(x,y,z)
 -- TouchUI.Button:press(x,y,y)
 -- confirmbutton:press(x,y,y)
 -- confirmbutton:redraw()
 -- cancelbutton:redraw()
end

m.release = function(x,y) end


m.redraw = function()
  screen.clear()
  screen.level(m.confirmed==false and 10 or 2)
  screen.move(64,40)
  screen.text_center(m.confirmed==false and "restart?" or "restarting.")
  --screen.move(49,70)
  --screen.rgblevel(15,0,0)
  --screen.text_center("NO")
  --screen.move(79,70)
  --screen.rgblevel(0,15,0)
  --screen.text_center("YES")
  screen.stroke()
  confirmbutton:redraw()
  cancelbutton:redraw()
  screen.update()
 

end

m.init = function() end
m.deinit = function() end

return m
