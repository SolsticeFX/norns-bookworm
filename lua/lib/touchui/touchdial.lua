--touchui = require 'lib/touchui'
-------- Dial --------
-- @section Dial

Dial = {}
Dial.__index = Dial
DialList = {}

--- Create a new Dial object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number size Diameter of dial, defaults to 22.
-- @tparam number value Current value, defaults to 0.
-- @tparam number min_value Minimum value, defaults to 0.
-- @tparam number max_value Maximum value, defaults to 1.
-- @tparam number rounding Sets precision to round value to, defaults to 0.01.
-- @tparam number start_value Sets where fill line is drawn from, defaults to 0.
-- @tparam table markers Array of marker positions.
-- @tparam string units String to display after value text.
-- @tparam string title String to be displayed instead of value text.
-- @treturn Dial Instance of Dial.

function Dial.new(x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title, encoder, tapcallback)
  local markers_table = markers or {}
  min_value = min_value or 0
  local dial = {
    x = x or 0,
    y = y or 0,
    size = size or 22,
    value = value or 0,
    min_value = min_value,
    max_value = max_value or 1,
    rounding = rounding or 0.01,
    start_value = start_value or min_value,
    units = units,
    title = title or nil,
    encoder = encoder or 0,
    tapcallback = tapcallback,
    active = true,
    _start_angle = math.pi * 0.7,
    _end_angle = math.pi * 2.3,
    _markers = {},
    _marker_points = {},
    color = {r,g,b}
  }
  setmetatable(Dial, {__index = Dial})
  setmetatable(dial, Dial)
  for k, v in pairs(markers_table) do
    dial:set_marker_position(k, v)
  end
  drag =  Dial.drag
  --tap = Dial.tap
  --press = Dial.press
  --release = Dial.release
  enc = Dial.enc
  table.insert(DialList, dial)
  return dial
end

Dial.tap=function(x,y)

   for i=1,#DialList do
    if (x - DialList[i].x)^2 + (y - DialList[i].y)^2 < (DialList[i].size)^2 then
      DialList[i].tapcallback()
    end
    --  if ((x>DialList[i].x-DialList[i].width/2) and (y>DialList[i].y-DialList[i].height/2) and (x<(DialList[i].x+DialList[i].width/2)) and (y<(DialList[i].y+DialList[i].height/2))) then
       -- DialList[i].pressed = true
        --print("Dial Pressed: ".. i)
        --DialList[i].callback()
   --   end
   end
end


Dial.enc=function(n,delta)
  for i=1,#DialList do
    if DialList[i].encoder == n and DialList[i].active then
      DialList[i]:set_value_delta(delta)
    end
  end
end

Dial.drag=function(gx ,gy, start_x, start_y, last_x, last_y)
  start_x=start_x/800*128
  start_y=start_y/480*70
  gy=gy/480*70
  last_y=last_y/480*70
  
  for i=1,#DialList do
    --radius = (DialList[i].size)/2
    if (start_x - DialList[i].x)^2 + (start_y - DialList[i].y)^2 < (DialList[i].size)^2 then
      number = DialList[i].value-gy+last_y
      DialList[i].value = util.clamp(number, DialList[i].min_value, DialList[i].max_value)
      DialList[i]:redraw()
  end
end
Tabs.drag(gx ,gy, start_x, start_y, last_x, last_y)
end


--- Set value.
-- @tparam number number Value number.
function Dial:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
end

--- Set value using delta.
-- @tparam number delta Number.
function Dial:set_value_delta(delta)
  self:set_value(self.value + delta)
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function Dial:set_marker_position(id, position)
  self._markers[id] = util.clamp(position, self.min_value, self.max_value)
  
  local radius = self.size * 0.5
  local marker_length = 3
  
  local marker_in = radius - marker_length
  local marker_out = radius + marker_length
  local marker_angle = util.linlin(self.min_value, self.max_value, self._start_angle, self._end_angle, self._markers[id])
  local x_center = self.x + self.size / 2
  local y_center = self.y + self.size / 2
  self._marker_points[id] = {}
  self._marker_points[id].x1 = x_center + math.cos(marker_angle) * marker_in
  self._marker_points[id].y1 = y_center + math.sin(marker_angle) * marker_in
  self._marker_points[id].x2 = x_center + math.cos(marker_angle) * marker_out
  self._marker_points[id].y2 = y_center + math.sin(marker_angle) * marker_out
end

--- Set dial's active state.
-- @tparam boolean state Boolean, true for active.
function Dial:set_active(state)
  self.active = state
end

--- Redraw Dial.
-- Call when changed.
function Dial:redraw()
  local radius = self.size * 0.5
  
  local fill_start_angle = util.linlin(self.min_value, self.max_value, self._start_angle, self._end_angle, self.start_value)
  local fill_end_angle = util.linlin(self.min_value, self.max_value, self._start_angle, self._end_angle, self.value)
  
  if fill_end_angle < fill_start_angle then
    local temp_angle = fill_start_angle
    fill_start_angle = fill_end_angle
    fill_end_angle = temp_angle
  end
  
  screen.level(5)
  screen.arc(self.x + radius, self.y + radius, radius - 0.5, self._start_angle, self._end_angle)
  screen.stroke()
  
 

  for _, v in pairs(self._marker_points) do
    screen.move(v.x1, v.y1)
    screen.line(v.x2, v.y2)
    screen.stroke()
  end
  
  --screen.level(15)
  if self.active then
    --print(norns.encoders.get_color(self.encoder))
    screen.hexrgblevel(norns.encoders.get_active_color(self.encoder))
   -- norns.encoders.set_rgb(self.encoder)
  else
    screen.hexrgblevel(norns.encoders.get_inactive_color(self.encoder))

  end

  screen.line_width(2.5)
  screen.arc(self.x + radius, self.y + radius, radius - 0.5, fill_start_angle, fill_end_angle)
  screen.stroke()
  screen.line_width(1)
  
  local title
  if self.title then
    title = self.title
  else
    title = util.round(self.value, self.rounding)
    if self.units then
      title = title .. " " .. self.units
    end
  end
  if self.active then screen.level(15) else screen.level(3) end
  screen.move(self.x + radius, self.y + self.size + 6)
  screen.text_center(title)
  screen.fill()
end


return Dial