--- TouchUI widgets module.
-- Widgets for paging, tabs, lists, dials, sliders, etc.
--
-- @module lib.TouchUI
-- @release v1.0.2
-- @author Mark Eats

local TouchUI = {}
TouchUI.__index = TouchUI



-------- Pages --------

--- Pages
-- @section Pages

TouchUI.Pages = {}
TouchUI.Pages.__index = TouchUI.Pages

--- Create a new Pages object.
-- @tparam number index Selected page, defaults to 1.
-- @tparam number num_pages Total number of pages, defaults to 3.
-- @treturn Pages Instance of Pages.
function TouchUI.Pages.new(index, num_pages)
  local pages = {
    index = index or 1,
    num_pages = num_pages or 3
  }
  setmetatable(TouchUI.Pages, {__index = TouchUI})
  setmetatable(pages, TouchUI.Pages)
  return pages
end

--- Set selected page.
-- @tparam number index Page number.
function TouchUI.Pages:set_index(index)
  self.index = util.clamp(index, 1, self.num_pages)
end

--- Set selected page using delta.
-- @tparam number delta Number to move from selected page.
-- @tparam boolean wrap Boolean, true to wrap pages.
function TouchUI.Pages:set_index_delta(delta, wrap)
  local index = self.index + delta
  if wrap then
    while index > self.num_pages do index = index - self.num_pages end
    while index < 1 do index = index + self.num_pages end
  end
  self:set_index(index)
end

--- Redraw Pages.
-- Call when changed.
function TouchUI.Pages:redraw()
  local dot_height = util.clamp(util.round(64 / self.num_pages - 2), 1, 4)
  local dot_gap = util.round(util.linlin(1, 4, 1, 2, dot_height))
  local dots_y = util.round((64 - self.num_pages * dot_height - (self.num_pages - 1) * dot_gap) * 0.5)
  for i = 1, self.num_pages do
    if i == self.index then screen.level(5)
    else screen.level(1) end
    screen.rect(127, dots_y, 1, dot_height)
    screen.fill()
    dots_y = dots_y + dot_height + dot_gap
  end
end


-------- Tabs --------

--- Tabs
-- @section Tabs

TouchUI.Tabs = {}
TouchUI.Tabs.__index = TouchUI.Tabs

--- Create a new Tabs object.
-- @tparam number index Selected tab, defaults to 1.
-- @tparam {string,...} titles Table of strings for tab titles.
-- @treturn Tabs Instance of Tabs.
function TouchUI.Tabs.new(index, titles)
  local tabs = {
    index = index or 1,
    titles = titles or {}
  }
  setmetatable(TouchUI.Tabs, {__index = TouchUI})
  setmetatable(tabs, TouchUI.Tabs)
  return tabs
end

--- Set selected tab.
-- @tparam number index Tab number.
function TouchUI.Tabs:set_index(index)
  self.index = util.clamp(index, 1, #self.titles)
end

--- Set selected tab using delta.
-- @tparam number delta Number to move from selected tab.
-- @tparam boolean wrap Boolean, true to wrap tabs.
function TouchUI.Tabs:set_index_delta(delta, wrap)
  local index = self.index + delta
  local count = #self.titles
  if wrap then
    while index > count do index = index - count end
    while index < 1 do index = index + count end
  end
  self:set_index(index)
end

--- Redraw Tabs.
-- Call when changed.
function TouchUI.Tabs:redraw()
  local MARGIN = 8
  local GUTTER = 14
  local col_width = (128 - (MARGIN * 2) - GUTTER * (#self.titles - 1)) / #self.titles
  for i = 1, #self.titles do
    if i == self.index then screen.rgblevel(15,15,3)
    else screen.level(3,3,0) end
    screen.move(MARGIN + col_width * 0.5 + ((col_width + GUTTER) * (i - 1)), 6)
    screen.text_center(self.titles[i])
  end
  screen.fill()
end


-------- List --------

--- List
-- @section List
TouchUI.List = {}
TouchUI.List.__index = TouchUI.List

--- Create a new List object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number index Selected entry, defaults to 1.
-- @tparam {string,...} entries Table of strings for list entries.
-- @treturn List Instance of List.
function TouchUI.List.new(x, y, index, entries)
  local list = {
    x = x or 0,
    y = y or 0,
    index = index or 1,
    entries = entries or {},
    text_align = "left",
    active = true
  }
  setmetatable(TouchUI.List, {__index = TouchUI})
  setmetatable(list, TouchUI.List)
  return list
end

--- Set selected entry.
-- @tparam number index Entry number.
function TouchUI.List:set_index(index)
  self.index = util.clamp(index, 1, #self.entries)
end

--- Set selected list using delta.
-- @tparam number delta Number to move from selected entry.
-- @tparam boolean wrap Boolean, true to wrap list.
function TouchUI.List:set_index_delta(delta, wrap)
  local index = self.index + delta
  local count = #self.entries
  if wrap then
    while index > count do index = index - count end
    while index < 1 do index = index + count end
  end
  self:set_index(index)
end

--- Set selected list's active state.
-- @tparam boolean state Boolean, true for active.
function TouchUI.List:set_active(state)
  self.active = state
end

--- Redraw List.
-- Call when changed.
function TouchUI.List:redraw()
  for i = 1, #self.entries do
    if self.active and i == self.index then screen.level(15)
    else screen.level(3) end
    screen.move(self.x, self.y + 5 + (i - 1) * 11)
    local entry = self.entries[i] or ""
    if self.text_align == "center" then
      screen.text_center(entry)
    elseif self.text_align == "right" then
      screen.text_right(entry)
    else
      screen.text(entry)
    end
  end
  screen.fill()
end


-------- ScrollingList --------

--- ScrollingList
-- @section Scrollinglist
TouchUI.ScrollingList = {}
TouchUI.ScrollingList.__index = TouchUI.ScrollingList

--- Create a new ScrollingList object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number index Selected entry, defaults to 1.
-- @tparam {string,...} entries Table of strings for list entries.
-- @treturn ScrollingList Instance of ScrollingList.
function TouchUI.ScrollingList.new(x, y, index, entries, encoder)
  local list = {
    x = x or 0,
    y = y or 0,
    index = index or 1,
    entries = entries or {},
    num_visible = 5,
    num_above_selected = 1,
    text_align = "left",
    active = true,
    encoder = encoder or 0
  }
  setmetatable(TouchUI.ScrollingList, {__index = TouchUI})
  setmetatable(list, TouchUI.ScrollingList)
  return list
end

--- Set selected entry.
-- @tparam number index Entry number.
function TouchUI.ScrollingList:set_index(index)
  self.index = util.clamp(index, 1, #self.entries)
end

--- Set selected scrolling list using delta.
-- @tparam number delta Number to move from selected entry.
-- @tparam boolean wrap Boolean, true to wrap list.
function TouchUI.ScrollingList:set_index_delta(delta, wrap)
  local index = self.index + delta
  local count = #self.entries
  if wrap then
    while index > count do index = index - count end
    while index < 1 do index = index + count end
  end
  self:set_index(index)
end

--- Set selected scrolling list's active state.
-- @tparam boolean state Boolean, true for active.
function TouchUI.ScrollingList:set_active(state)
  self.active = state
end

--- Redraw ScrollingList.
-- Call when changed.
function TouchUI.ScrollingList:redraw()
  
  local num_entries = #self.entries
  local scroll_offset = self.index - 1 - math.max(self.index - (num_entries - 2), 0)
  scroll_offset = scroll_offset - util.linlin(num_entries - self.num_above_selected, num_entries, self.num_above_selected, 0, self.index - 1) -- For end of list
  
  for i = 1, self.num_visible do
    if self.active and self.index == i + scroll_offset then norns.encoders.set_rgb(self.encoder)
    else screen.level(3) end
    screen.move(self.x, self.y + 5 + (i - 1) * 11)
    local entry = self.entries[i + scroll_offset] or ""
    if self.text_align == "center" then
      screen.text_center(entry)
    elseif self.text_align == "right" then
      screen.text_right(entry)
    else
      screen.text(entry)
    end
  end
  screen.fill()
end



-------- Message --------

--- Message
-- @section Message
TouchUI.Message = {}
TouchUI.Message.__index = TouchUI.Message

--- Create a new Message object.
-- @tparam [string,...] text_array Array of lines of text.
-- @treturn Message Instance of Message.
function TouchUI.Message.new(text_array)
  local message = {
    text = text_array or {},
    active = true
  }
  setmetatable(TouchUI.Message, {__index = TouchUI})
  setmetatable(message, TouchUI.Message)
  return message
end

--- Set message's active state.
-- @tparam boolean state Boolean, true for active.
function TouchUI.Message:set_active(state)
  self.active = state
end

--- Redraw Message.
-- Call when changed.
function TouchUI.Message:redraw()
  local LINE_HEIGHT = 11
  local y = util.round(34 - LINE_HEIGHT * (#self.text - 1) * 0.5)
  for i = 1, #self.text do
    if self.active then screen.level(15)
    else screen.level(3) end
    screen.move(64, y)
    screen.text_center(self.text[i])
    y = y + 11
  end
  screen.fill()
end


-------- Slider --------

--- Slider
-- @section Slider
TouchUI.Slider = {}
TouchUI.Slider.__index = TouchUI.Slider
--TouchUI.Slider.bigmarkerwidth = 12
--TouchUI.Slider.sliderwidth = 10
--TouchUI.Slider.markerwidth = 5
--TouchUI.Slider.linesabove = 5
--TouchUI.Slider.linesbelow = 15


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
function TouchUI.Slider.new(x, y, width, height, value, min_value, max_value, markers, direction, dividers, encoder, slider_width, slider_height)
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
  setmetatable(TouchUI.Slider, {__index = TouchUI})
  setmetatable(slider, TouchUI.Slider)
  return slider
end

--- Set value.
-- @tparam number number Value number.
function TouchUI.Slider:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
end

--- Set value using delta.
-- @tparam number delta Number.
function TouchUI.Slider:set_value_delta(delta)
  self:set_value(self.value + delta)
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function TouchUI.Slider:set_marker_position(id, position)
  self.markers[id] = util.clamp(position, self.min_value, self.max_value)
end

--- Set slider's active state.
-- @tparam boolean state Boolean, true for active.
function TouchUI.Slider:set_active(state)
  self.active = state
end

--- Redraw Slider.
-- Call when changed.
function TouchUI.Slider:redraw()
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
  
  
  --local filled_height = util.round(util.linlin(self.min_value, self.max_value, 0, self.height, self.value))
  --screen.rect(self.x, self.y + self.height - filled_height, self.width, filled_height)
  

  --draw the slider
  local filled_amount --sometimes width now
  if self.direction == "up" then
      filled_amount = util.round(util.linlin(self.min_value, self.max_value, 0, self.height, self.value))
      if self.active and self.encoder > 0 then
        screen.line_width(1)
        norns.encoders.set_rgb(self.encoder)
        screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount,self.slider_width+2,self.slider_height+2,1)
        screen.stroke()
      end
      screen.rounded_rect_center(self.x + self.width/2,self.y + filled_amount,self.slider_width,self.slider_height,1)
    elseif self.direction == "down" then
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


-------- Dial --------

--- Dial
-- @section Dial
TouchUI.Dial = {}
TouchUI.Dial.__index = TouchUI.Dial

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

function TouchUI.Dial.new(x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title, encoder)
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
    active = true,
    _start_angle = math.pi * 0.7,
    _end_angle = math.pi * 2.3,
    _markers = {},
    _marker_points = {}
  }
  setmetatable(TouchUI.Dial, {__index = TouchUI})
  setmetatable(dial, TouchUI.Dial)
  for k, v in pairs(markers_table) do
    dial:set_marker_position(k, v)
  end
  return dial
end

--- Set value.
-- @tparam number number Value number.
function TouchUI.Dial:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
end

--- Set value using delta.
-- @tparam number delta Number.
function TouchUI.Dial:set_value_delta(delta)
  self:set_value(self.value + delta)
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function TouchUI.Dial:set_marker_position(id, position)
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
function TouchUI.Dial:set_active(state)
  self.active = state
end

--- Redraw Dial.
-- Call when changed.
function TouchUI.Dial:redraw()
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
  
  screen.level(15)
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


-------- PlaybackIcon --------

--- PlaybackIcon
-- @section PlaybackIcon
TouchUI.PlaybackIcon = {}
TouchUI.PlaybackIcon.__index = TouchUI.PlaybackIcon

--- Create a new PlaybackIcon object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number size Icon size, defaults to 6.
-- @tparam number status Status number. 1 = Play, 2 = Reverse Play, 3 = Pause, 4 = Stop. Defaults to 1.
-- @treturn PlaybackIcon Instance of PlaybackIcon.
function TouchUI.PlaybackIcon.new(x, y, size, status)
  local playback_icon = {
    x = x or 0,
    y = y or 0,
    size = size or 6,
    status = status or 1,
    active = true
  }
  setmetatable(TouchUI.PlaybackIcon, {__index = TouchUI})
  setmetatable(playback_icon, TouchUI.PlaybackIcon)
  return playback_icon
end

--- Set PlaybackIcon's status.
-- @tparam number status Status number. 1 = Play, 2 = Reverse Play, 3 = Pause, 4 = Stop.
function TouchUI.PlaybackIcon:set_status(status)
  self.status = status
end

--- Set PlaybackIcon's active state.
-- @tparam boolean state Boolean, true for active.
function TouchUI.PlaybackIcon:set_active(state)
  self.active = state
end

--- Redraw PlaybackIcon.
-- Call when changed.
function TouchUI.PlaybackIcon:redraw()
  if self.active then screen.rgblevel(15,15,6)
  else screen.rgblevel(3) end
  -- Play
  if self.status == 1 then
    screen.move(self.x, self.y)
    screen.line(self.x + self.size, self.y + self.size * 0.5)
    screen.line(self.x, self.y + self.size)
    screen.close()
  -- Reverse Play
  elseif self.status == 2 then
    screen.move(self.x + self.size, self.y)
    screen.line(self.x, self.y + self.size * 0.5)
    screen.line(self.x + self.size, self.y + self.size)
    screen.close()
  -- Pause
  elseif self.status == 3 then
    screen.rect(self.x, self.y, util.round(self.size * 0.4), self.size)
    screen.rect(self.x + util.round(self.size * 0.6), self.y, util.round(self.size * 0.4), self.size)
  -- Stop
  else
    screen.rect(self.x, self.y, self.size, self.size)
  end
  screen.fill()
end


return TouchUI
