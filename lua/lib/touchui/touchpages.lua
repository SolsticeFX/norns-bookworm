-------- Pages --------
-- @section Pages

Pages = {}
Pages.__index = Pages

--- Create a new Pages object.
-- @tparam number index Selected page, defaults to 1.
-- @tparam number num_pages Total number of pages, defaults to 3.
-- @treturn Pages Instance of Pages.
function Pages.new(index, num_pages)
  local pages = {
    index = index or 1,
    num_pages = num_pages or 3
  }
  setmetatable(Pages, {__index = Pages})
  setmetatable(pages, Pages)
  return pages
end

--- Set selected page.
-- @tparam number index Page number.
function Pages:set_index(index)
  self.index = util.clamp(index, 1, self.num_pages)
end

--- Set selected page using delta.
-- @tparam number delta Number to move from selected page.
-- @tparam boolean wrap Boolean, true to wrap pages.
function Pages:set_index_delta(delta, wrap)
  local index = self.index + delta
  if wrap then
    while index > self.num_pages do index = index - self.num_pages end
    while index < 1 do index = index + self.num_pages end
  end
  self:set_index(index)
end

--- Redraw Pages.
-- Call when changed.
function Pages:redraw()
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

return Pages