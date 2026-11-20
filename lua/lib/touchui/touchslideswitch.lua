--- SlideSwitch
-- A Solstice two-position slide switch, after Teenage Engineering's: a thin vertical slot between
-- two words, with a translucent thumb (in its key's colour) that sits at the chosen one.
--
-- A press of its key flips it, a tap on it flips it, and a finger can slide the thumb: it follows
-- along the slot and snaps to the nearer end on release. The thumb glides between ends (no bounce).
--
--   local SlideSwitch = require 'touchui/touchslideswitch'
--   local sw = SlideSwitch.new{
--     x = 7, top = 18, bot = 64,          -- centre x, and the top / bottom of the whole switch
--     labels = {"one", "two"}, key = 2,
--     on_change = function(v) editing = v end,   -- v is 1 (top) or 2 (bottom)
--   }
--   function key(n, z) if sw:key(n, z) then return end ... end
--   function press(x, y) if sw:press(x / 6.25, y / 6.25) then return end ... end
--   function drag(x, y) if sw:drag(x / 6.25, y / 6.25) then return end ... end
--   function release(x, y) if sw:release(x / 6.25, y / 6.25) then return end ... end
--   -- and in redraw(): sw:redraw()
--
-- Coordinates are canvas units (raw touch px / 6.25 on the 128x76 Solstice canvas).
-- sw:set(v) moves it from the script (it glides there; on_change is not called), sw.value reads it.
-- While gliding it calls redraw() 60 times a second; pass redraw = false (if the script redraws
-- on a metro anyway) or a function to call instead. key = nil makes it touch-only.

local util = require 'util'

local SlideSwitch = {}
SlideSwitch.__index = SlideSwitch

local FALLBACK = {0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF}

local function hex(c)
  if screen.hexrgblevel then
    screen.hexrgblevel(c)
  else
    local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
    screen.level(math.floor((r + g + b) / 3 / 17))
  end
end

local function grey(l) hex(math.floor(l * 17) * 0x010101) end

local function faded(c)
  if screen.fadedColor then return screen.fadedColor(c, 0xA0) end
  local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
  return ((r * 3 // 8) << 16) | ((g * 3 // 8) << 8) | (b * 3 // 8)
end

-- dark LED colours mixed toward white until they read on black
local function legible(c)
  local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
  local lum = 0.3 * r + 0.55 * g + 0.15 * b
  if lum >= 110 then return c end
  local k = util.clamp((110 - lum) / 200, 0, 0.6)
  local function mix(v) return math.floor(v + (255 - v) * k) end
  return (mix(r) << 16) | (mix(g) << 8) | mix(b)
end

local function key_colour(n)
  local ok, c = pcall(norns.encoders.get_active_color, n)
  if ok and type(c) == "number" then return legible(c) end
  return FALLBACK[n] or 0xF2F2F2
end

--- Create a slide switch.
-- @tparam table o x (centre), top, bot (the whole switch, labels included; canvas units);
--   labels ({top, bottom}); key (its key, also its colour; nil = touch only); value (1 or 2);
--   on_change(v); thumb (size, default 9); hit_w (touch half-width, default 10); redraw.
function SlideSwitch.new(o)
  local s = setmetatable({}, SlideSwitch)
  s.x, s.top, s.bot = o.x or 7, o.top or 18, o.bot or 64
  s.labels = o.labels or {"one", "two"}
  s.btkey = o.key
  s.colour = o.colour        -- optional fixed colour instead of the key's
  s.value = o.value or 1
  s.on_change = o.on_change or function() end
  s.thumb = o.thumb or 9
  s.hit_w = o.hit_w or 10
  if o.redraw == false then s.redraw_fn = function() end
  else s.redraw_fn = o.redraw or function() if redraw then redraw() end end end
  -- the slot runs between the labels; the stops sit a thumb's half-height in from its ends
  s.slot_top, s.slot_bot = s.top + 8, s.bot - 8
  s.y1, s.y2 = s.slot_top + s.thumb / 2 + 0.5, s.slot_bot - s.thumb / 2 - 0.5
  s.pos = s.value - 1        -- drawn position, 0 (top) .. 1 (bottom)
  s.drag_pos = nil
  s.gliding = false
  s.touch = nil
  return s
end

function SlideSwitch:glide()
  if self.gliding then return end
  self.gliding = true
  clock.run(function()
    while true do
      if not self.drag_pos then
        local target = self.value - 1
        self.pos = self.pos + (target - self.pos) * 0.3
        if math.abs(target - self.pos) < 0.002 then
          self.pos = target
          break
        end
      end
      self.redraw_fn()
      clock.sleep(1 / 60)
    end
    self.gliding = false
    self.redraw_fn()
  end)
end

--- Move it to v (1 or 2) from the script: it glides there, on_change is not called.
function SlideSwitch:set(v)
  if v ~= self.value then
    self.value = v
    self:glide()
  end
end

--- Flip it (as K or a tap does): glides over and calls on_change.
function SlideSwitch:toggle()
  self.value = 3 - self.value
  -- tell the script first: glide() redraws straight away, and a redraw that calls
  -- set(script's value) would otherwise put it straight back
  self.on_change(self.value)
  self:glide()
end

--- Pass key events through. Returns true if the event was this switch's key.
function SlideSwitch:key(n, z)
  if not self.btkey or n ~= self.btkey then return false end
  if z == 1 then self:toggle() end
  return true
end

function SlideSwitch:hit(x, y)
  return math.abs(x - self.x) <= self.hit_w and y >= self.top - 2 and y <= self.bot + 2
end

--- Pass touch presses through (canvas units). Returns true if the press landed on the switch.
function SlideSwitch:press(x, y)
  if not self:hit(x, y) then return false end
  self.touch = {y0 = y, moved = false}
  return true
end

--- Pass drags through. Returns true while a touch that started on the switch is sliding it.
function SlideSwitch:drag(x, y)
  local t = self.touch
  if not t then return false end
  if math.abs(y - t.y0) > 2 then t.moved = true end
  if t.moved then
    self.drag_pos = util.clamp((y - self.y1) / (self.y2 - self.y1), 0, 1)
    self:glide()
  end
  return true
end

--- Pass releases through. Returns true if it ended a touch on the switch.
function SlideSwitch:release(x, y)
  local t = self.touch
  if not t then return false end
  self.touch = nil
  if t.moved and self.drag_pos then
    -- let go: it snaps to whichever end is nearer
    self.pos, self.drag_pos = self.drag_pos, nil
    local v = self.pos >= 0.5 and 2 or 1
    if v ~= self.value then
      self.value = v
      self.on_change(v)
    end
    self:glide()
  else
    self:toggle()
  end
  self.redraw_fn()
  return true
end

function SlideSwitch:redraw()
  local p = self.drag_pos or self.pos
  local cx, tw = self.x, self.thumb
  local ty = self.y1 + p * (self.y2 - self.y1)
  local c = self.colour or (self.btkey and key_colour(self.btkey)) or 0xF2F2F2
  screen.aa(1)
  screen.line_width(1)
  -- the slot: a plain line
  grey(3)
  screen.move(cx, self.slot_top)
  screen.line(cx, self.slot_bot)
  screen.stroke()
  -- the thumb: translucent (the slot shows through), with a bright edge and grip lines
  local x0, y0 = cx - tw / 2, ty - tw / 2
  hex(faded(c))
  screen.blend_mode("add")
  screen.move(x0, y0 + 1.5)
  screen.rounded_rect(x0, y0, tw, tw, 1.5)
  screen.fill()
  screen.blend_mode(0)
  hex(c)
  screen.line_width(0.8)
  screen.move(x0 + 0.4, y0 + 1.9)
  screen.rounded_rect(x0 + 0.4, y0 + 0.4, tw - 0.8, tw - 0.8, 1.2)
  screen.stroke()
  for k = -1, 1 do
    screen.move(x0 + 2.5, ty + k * 2)
    screen.line_rel(tw - 5, 0)
    screen.stroke()
  end
  screen.line_width(1)
  screen.aa(0)
  -- the words at either end; the chosen one is lit
  screen.font_face(1)
  screen.font_size(8)
  grey(self.value == 1 and 15 or 3)
  screen.move(cx, self.top + 5)
  screen.text_center(self.labels[1])
  grey(self.value == 2 and 15 or 3)
  screen.move(cx, self.bot)
  screen.text_center(self.labels[2])
end

return SlideSwitch
