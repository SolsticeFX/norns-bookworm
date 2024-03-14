-------- Slider --------
-- @section Slider
Slider = {}
Slider.__index = Slider
--Slider.bigmarkerwidth = 12
--Slider.sliderwidth = 10
--Slider.markerwidth = 5
--Slider.linesabove = 5
--Slider.linesbelow = 15


--- Create a new Slider object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number width Width of widget, defaults to 10.
-- @tparam number height Height of widget, defaults to 36.
-- @tparam number value Current value, defaults to 0.
-- @tparam number min_value Minimum value, defaults to 0.
-- @tparam number max_value Maximum value, defaults to 1.
-- @tparam table markers Array of marker positions.
-- @tparam string the direction of the slider "up" (defult), down, left, right
-- @tparam number dividers Evenly spaced markers, overrides marker tables if set
-- @tparam number encoder Assigned encoder number
-- @tparam number slider_width Width of slider, defaults to 10.
-- @tparam number slider_height Height of slider, defaults to 5.
-- @treturn Slider Instance of Slider.
function Slider.new(x, y, width, height, value, min_value, max_value, markers, direction, dividers, encoder, slider_width, slider_height)
  local slider = {
    x = x or 0,
    y = y or 0,
    width = width or 6,
    height = height or 36,
    value = value or 0,
    min_value = min_value or 0,
    max_value = max_value or 1,
    markers = markers or {},
    active = true,
    direction = direction or "up",
    dividers = dividers or 0,
    encoder = encoder or 0,
    slider_width = slider_width or 10,
    slider_height = slider_height or 5
  }
  local acceptableDirections = {"up","down","left","right"}
  
  if (acceptableDirections[direction] == nil) then direction = acceptableDirections[1] end
  setmetatable(Slider, {__index = Slider})
  setmetatable(slider, Slider)
  return slider
end

--- Set value.
-- @tparam number number Value number.
function Slider:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
end

--- Set value using delta.
-- @tparam number delta Number.
function Slider:set_value_delta(delta)
  self:set_value(self.value + delta)
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function Slider:set_marker_position(id, position)
  self.markers[id] = util.clamp(position, self.min_value, self.max_value)
end

--- Set slider's active state.
-- @tparam boolean state Boolean, true for active.
function Slider:set_active(state)
  self.active = state
  print("act0i"..state)
end


--m.enc = function(n,delta)
 -- print("enci"..n)
--end


function Slider:enc(n,delta)
 print("enci"..n)
end



--- Redraw Slider.
-- Call when changed.
function Slider:redraw()
  print("reeee")
  screen.line_width(0.4)

  screen.level(6)
  --[[
  --draws the perimeter 
  if (self.direction == "up" or self.direction == "down") then
   -- screen.rect(self.x + 0.5, self.y + 0.5, self.width - 1, self.height - 1) 
  elseif (self.direction == "left" or self.direction == "right") then
  -- screen.rect(self.x + 0.5, self.y + 0.5, self.width - 1, self.height - 1)
  end 
    
  screen.stroke()
  ]]


--draw markers
if self.dividers > 0 then
    if self.direction == "up" or self.direction == "down"  then
      for j=1,self.dividers+1 do
        screen.move(self.x, (self.y +(j*(self.height)/self.dividers)))
        screen.line_rel(self.width,0)
        screen.stroke()
      end
    elseif self.direction == "left" or self.direction == "right"  then
      for j=1,self.dividers+1 do
        screen.move((self.x +(j*(self.width)/self.dividers)), self.y)
        screen.line_rel(0,self.height)
        screen.stroke()
      end
    end
  
else
  for _, v in pairs(self.markers) do
    if self.direction == "up" then
      screen.rect(self.x - 2, util.round(self.y + util.linlin(self.min_value, self.max_value, self.height - 1, 0, v)), self.width + 4, 1) --original
    elseif self.direction == "down" then
      screen.rect(self.x - 2, util.round(self.y + util.linlin(self.min_value, self.max_value, 0,self.height - 1, v)), self.width + 4, 1)
    elseif self.direction == "left" then
      screen.rect(util.round(self.x + util.linlin(self.min_value, self.max_value, self.width - 1, 0, v)), self.y - 2, 1, self.height +4)
    elseif self.direction == "right" then
      screen.rect(util.round(self.x + util.linlin(self.min_value, self.max_value, 0, self.width - 1, v)), self.y - 2, 1, self.height +4)
    end
  end
end

  screen.fill()

  --draw the slider
  local filled_amount --sometimes width now
  if self.direction == "up" then
    screen.level(15)
    screen.rounded_rect_center(self.x + self.width/2,self.y+self.height/2,2, self.height,1)
    screen.fill()
      filled_amount = util.round(util.linlin(self.min_value, self.max_value, 0, self.height, self.value))
      if self.active and self.encoder > 0 then
        screen.line_width(1)
        norns.encoders.set_rgb(self.encoder)
        screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount,self.slider_width+2,self.slider_height+2,1)
        screen.stroke()

      end
      screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount,self.slider_width,self.slider_height,1)
    elseif self.direction == "down" then
      screen.level(15)
      screen.rounded_rect_center(self.x + self.width/2, self.y + self.height/2, 2, self.height,1)
      screen.stroke()
      filled_amount = util.round(util.linlin(self.min_value, self.max_value, 0, self.height, self.value)) --same as up
      if self.active and self.encoder > 0 then
        screen.line_width(1)
        norns.encoders.set_rgb(self.encoder)
        screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount,self.slider_width+2,self.slider_height+2,1)
        screen.stroke()

      end
      screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount  ,self.slider_width,self.slider_height,1)

    elseif self.direction == "left" then
      filled_amount = util.round(util.linlin(self.min_value, self.max_value, 0, self.width, self.value))
      if self.active and self.encoder > 0 then
        screen.line_width(1)
        norns.encoders.set_rgb(self.encoder)
        screen.rounded_rect_center(self.x - filled_amount + self.width,self.y + 0.5*self.slider_height,self.slider_height+2,self.slider_width+2,1)
        screen.stroke()
      end
      screen.rounded_rect_center(self.x - filled_amount + self.width,self.y + 0.5*self.slider_height,self.slider_height,self.slider_width,1)

    elseif self.direction == "right" then
      filled_amount = util.round(util.linlin(self.min_value, self.max_value, 0, self.width, self.value))
      if self.active and self.encoder > 0 then
        screen.line_width(1)
        norns.encoders.set_rgb(self.encoder)
        screen.rounded_rect_center(self.x + filled_amount,self.y + 0.5*self.slider_height ,self.slider_height+2,self.slider_width+2,1)
        screen.stroke()
      end
      screen.rounded_rect_center(self.x + filled_amount,self.y + 0.5*self.slider_height ,self.slider_height,self.slider_width,1)
  end

  if self.active then screen.level(15) else screen.level(6) end
  screen.fill()
  screen.line_width(1)

end