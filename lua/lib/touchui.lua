--- TouchUI widgets module.
-- Widgets for paging, tabs, lists, dials, sliders, etc.
--
-- @module lib.TouchUI
-- @release v1.0.2
-- @author Mark Eats


-- global include function
function include(file)
  local dirs = {norns.state.path, _path.code, _path.extn, _path.globallib}
  for _, dir in ipairs(dirs) do
   -- print (dir)
    local p = dir..file..'.lua'
   -- print(p)
    if util.file_exists(p) then
    --  print("including "..p)
      return dofile(p)
    end
  end

  -- didn't find anything
 -- print("### MISSING INCLUDE: "..file)
  error("MISSING INCLUDE: "..file,2)
end



local TouchUI = {}
TouchUI.__index = TouchUI


TouchUI.Dial = include('/touchui/touchdial')
TouchUI.Pages = include('/touchui/touchpages')
TouchUI.Slider = include('/touchui/touchslider')
TouchUI.Button = include('/touchui/touchbutton')
TouchUI.Tabs = include('/touchui/touchtabs')

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
