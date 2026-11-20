-------- ScrollingButtonList --------
-- @section ScrollingButtonList
ScrollingButtonList = {}
ScrollingButtonList.__index = ScrollingButtonList
--ScrollingButtonList.bigmarkerwidth = 12
--ScrollingButtonList.scrollingListwidth = 10
--ScrollingButtonList.markerwidth = 5
--ScrollingButtonList.linesabove = 5
--ScrollingButtonList.linesbelow = 15



--- Create a new ScrollingButtonList object.
-- @tparam number x X position, defaults to 0.
-- @tparam number y Y position, defaults to 0.
-- @tparam number index Selected entry, defaults to 1.
-- @tparam {string,...} entries Table of strings for list entries.
-- @treturn ScrollingButtonList Instance of ScrollingButtonList.
function ScrollingButtonList.new(x, y, index, entries, btkey, callback)
  local list = {
    x = x or 0,
    y = y or 0,
    index = index or 1,
    entries = entries or {},
    btkey =  btkey,
    callback = callback,
    num_visible = 5,
    num_above_selected = 1,
    text_align = "left",
    active = true
  }
  setmetatable(ScrollingButtonList, {__index = ScrollingButtonList})
  setmetatable(list, ScrollingButtonList)
  return list
end



--- Set selected entry.
-- @tparam number index Entry number.
function ScrollingButtonList:set_index(index)
  self.index = util.clamp(index, 1, #self.entries)
end


--- Set selected scrolling list using delta.
-- @tparam number delta Number to move from selected entry.
-- @tparam boolean wrap Boolean, true to wrap list.
function ScrollingButtonList:set_index_delta(delta, wrap)
  local index = self.index + delta
  local count = #self.entries
  if wrap then
    while index > count do index = index - count end
    while index < 1 do index = index + count end
  end
  self:set_index(index)
end



--- Redraw ScrollingButtonList.
-- Call when changed.
function ScrollingButtonList:redraw()
  
  local num_entries = #self.entries
  local scroll_offset = self.index - 1 - math.max(self.index - (num_entries - 2), 0)
  scroll_offset = scroll_offset - util.linlin(num_entries - self.num_above_selected, num_entries, self.num_above_selected, 0, self.index - 1) -- For end of list
  
  for i = 1, self.num_visible do
    if self.active and self.index == i + scroll_offset then screen.level(15)
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



return ScrollingButtonList