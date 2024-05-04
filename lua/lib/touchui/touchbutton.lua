--- Button
Button = {}
Button.__index = Button

ButtonList = {}


function Button:new(x, y, width, height, label, btkey, callback)
   button = {
    x = x or 0,
    y = y or 0,
    width = width or 10,
    height = height or 5,
    label = label or "",
    btkey =  btkey,
    callback = callback,
    pressed = false,
  }
 -- setmetatable(Button, {__index = Button})
  setmetatable(button, Button)
      key = Button.key
      press = Button.press
      release = Button.release
      table.insert(ButtonList, button)
  return button
end



tttap=function(x,y)
  x=x/800*128
  y=y/480*64
   --   if ((x>button.x-button.width/2) and (y>button.y-button.height/2) and (x<(button.x+button.width/2)) and (y<(button.y+button.height/2))) then
      print("TAPpy")
      print(getmetatable(button))
      print(x,y)
--end 
end

function Button:tap(x,y)
  y=y/480*64
  --if ((x>self.x-self.width/2) and (y>self.y-self.height/2) and (x<(self.x+self.width/2)) and (y<(self.y+self.height/2))) then
  --print("TAP1")
  --print("HIHIHI")
  --callback()
  
--end 
end

function dump(t, indent, done)
  done = done or {}
  indent = indent or 0

  done[t] = true

  for key, value in pairs(t) do
      print(string.rep("\t", indent))

      if type(value) == "table" and not done[value] then
          done[value] = true
          print(key, ":\n")

          dump(value, indent + 2, done)
          done[value] = nil
      else
          print(key, "\t=\t", value, "\n")
      end
  end
end

Button.tap=function(x,y)
--TapCallback
end

--MARKED
Button.press=function(x,y)
  x=x/800*128
  y=y/480*70

   for i=1,#ButtonList do
      if ((x>ButtonList[i].x-ButtonList[i].width/2) and (y>ButtonList[i].y-ButtonList[i].height/2) and (x<(ButtonList[i].x+ButtonList[i].width/2)) and (y<(ButtonList[i].y+ButtonList[i].height/2))) then
        ButtonList[i].pressed = true
        print("Button Pressed: ".. i)
        ButtonList[i].callback()
        ButtonList[i]:redraw()
      end
    end

    --Dial.press(x,y)
end

Button.release=function(x,y)
  x=x/800*128
  y=y/480*64
   for i=1,#ButtonList do
    ButtonList[i].pressed = false
    ButtonList[i]:redraw()
   end
   Dial.tap(x,y)
end

function Button:key(n,z)
  for i=1,#ButtonList do
    if (n==ButtonList[i].btkey) then
      if z==0 then
        ButtonList[i].pressed = false
        ButtonList[i]:redraw()
      else
        ButtonList[i].pressed = true
        ButtonList[i]:redraw()
      end
    end

   end
   
 end

 function Button:enc(n,z)
  print('buttonprint')
  --self.exit()
   
 end

 function Button:redraw()

    screen.blend_mode(5)

    if self.pressed then

      screen.hexrgblevel(norns.encoders.get_active_color(self.btkey))
    else
    screen.hexrgblevel(norns.encoders.get_inactive_color(self.btkey))

    --self.set_inactive_rgb(self.btkey,self.btkey)
    end
  --screen.level(self.pressed and 10 or 3)
 
  screen.rounded_rect_center(self.x,self.y,self.width,self.height,2)
  screen.fill()
  screen.blend_mode(0)

  screen.level(15)
  screen.move(self.x, self.y)  
  screen.text_center(self.label)
  screen.stroke()


 end




 function Button:set_inactive_rgb(n)
  screen.hexrgblevel(norns.encoders.get_active_color(n))
end

function Button:set_active_rgb(n)
  screen.hexrgblevel(norns.encoders.get_inactive_color(n))
end


return Button
