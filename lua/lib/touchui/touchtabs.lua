
-------- Tabs --------

--- Tabs
-- @section Tabs

Tabs = {}
Tabs.__index = Tabs
TabsList = {}

--- Create a new Tabs object.
-- @tparam number index Selected tab, defaults to 1.
-- @tparam {string,...} titles Table of strings for tab titles.
-- @treturn Tabs Instance of Tabs.
function Tabs.new(index, titles, active)
  local tabs = {
    index = index or 1,
    titles = titles or {},
    active = true
  }
  setmetatable(Tabs, {__index = Tabs})
  setmetatable(tabs, Tabs)
  table.insert(TabsList, tabs)
  return tabs
end

--- Set selected tab.
-- @tparam number index Tab number.
function Tabs:set_index(index)
  self.index = util.clamp(index, 1, #self.titles)
end

--- Set selected tab using delta.
-- @tparam number delta Number to move from selected tab.
-- @tparam boolean wrap Boolean, true to wrap tabs.
function Tabs:set_index_delta(delta, wrap)
  local index = self.index + delta
  local count = #self.titles
  if wrap then
    while index > count do index = index - count end
    while index < 1 do index = index + count end
  end
  self:set_index(index)
end


Tabs.drag=function(gx,gy,start_x,start_y,last_x,last_y)

    if(start_y<40)then
    print("weeee")
    for i=1,#TabsList do
      print("weeee ".. i )
      local c = util.clamp(math.floor(gx/(800/#TabsList[i].titles))+1,1,#TabsList[i].titles)
      if c ~= TabsList[i].index then
        TabsList[i]:set_index(c)
      end
    end
      --  _menu.panel = c
      --  _menu.set_page(_menu.panels[_menu.panel])
      --end
    
 --   else _menu.pdrag(gx,gy,start_x,start_y,last_x,last_y) end
    
    end
  end
    
--- Redraw Tabs.
-- Call when changed.
function Tabs:redraw()
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

return Tabs