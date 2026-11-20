--- LongPressButton
-- A Solstice button for an action that needs a long press: hold its key (or hold a finger on it).
--
-- It looks like a top-bar toggle: its label, filled in while it is "on", plus a thin track
-- underneath in the key's colour. The track is what marks a long press. It fills while the key
-- or finger is held, and the long action fires when it is full. Letting go of the key early runs
-- the tap action instead (if there is one); letting go of a touch early does nothing.
--
--   local LongPressButton = require 'touchui/touchlongpressbutton'
--   local sunrise = LongPressButton.new{
--     x = 106, y = 1, width = 21, height = 6.5, label = "SUNRISE", key = 3,
--     on_long = function() toggle_sunrise() end,   -- the hold completed
--     on_tap = function() toggle_drift() end,      -- optional: key let go before that
--     is_on = function() return sunrise_on end,    -- optional: draws the filled "on" look
--   }
--   function key(n, z) if sunrise:key(n, z) then return end ... end
--   function press(x, y) if sunrise:press(x / 6.25, y / 6.25) then return end ... end
--   function release(x, y) if sunrise:release(x / 6.25, y / 6.25) then return end ... end
--   -- and in redraw(): sunrise:redraw()
--
-- Coordinates are canvas units (raw touch px / 6.25 on the 128x76 Solstice canvas).
-- While held, the button calls redraw() 30 times a second so the track animates. Pass
-- redraw = false if the script already redraws on a metro, or a function to call instead.
-- Colours follow the encoder of the same number (key colours match encoder colours).

local util = require 'util'

local LongPressButton = {}
LongPressButton.__index = LongPressButton

LongPressButton.HOLD = 0.45      -- seconds to fill the track
local FALLBACK = {0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF}

local function hex(c)
  if screen.hexrgblevel then
    screen.hexrgblevel(c)
  else
    local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
    screen.level(math.floor((r + g + b) / 3 / 17))
  end
end

local function dimmed(c, amount)
  local k = 1 - amount
  local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
  return (math.floor(r * k) << 16) | (math.floor(g * k) << 8) | math.floor(b * k)
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

--- Create a long press button.
-- @tparam table o x, y, width, height (canvas units); label; key (2..4, also picks the colour);
--   on_long; on_tap (optional); is_on (optional function); hold (seconds, default 0.45);
--   font_face (default 5), font_size (default 4.2); redraw (function, or false).
function LongPressButton.new(o)
  local b = setmetatable({}, LongPressButton)
  b.x, b.y = o.x or 0, o.y or 0
  b.width, b.height = o.width or 20, o.height or 6.5
  b.label = o.label or ""
  b.btkey = o.key or 3
  b.hold = o.hold or LongPressButton.HOLD
  b.on_long = o.on_long or function() end
  b.on_tap = o.on_tap
  b.is_on = o.is_on or function() return false end
  b.font_face, b.font_size = o.font_face or 5, o.font_size or 4.2
  if o.redraw == false then b.redraw_fn = function() end
  else b.redraw_fn = o.redraw or function() if redraw then redraw() end end end
  b.held = nil        -- {t0, fired, by = "key" | "touch"} while held
  return b
end

--- 0..1 while held and not yet fired, nil otherwise.
function LongPressButton:progress()
  local h = self.held
  if not h or h.fired then return nil end
  return util.clamp((util.time() - h.t0) / self.hold, 0, 1)
end

function LongPressButton:start(by)
  local h = {t0 = util.time(), fired = false, by = by}
  self.held = h
  clock.run(function()
    while self.held == h and not h.fired do
      if util.time() - h.t0 >= self.hold then
        h.fired = true
        self.on_long()
      end
      self.redraw_fn()
      if not h.fired then clock.sleep(1 / 30) end
    end
  end)
end

--- Pass key events through. Returns true if the event was this button's key.
function LongPressButton:key(n, z)
  if n ~= self.btkey then return false end
  if z == 1 then
    self:start("key")
  else
    local h = self.held
    if h and h.by == "key" then
      self.held = nil
      if not h.fired and self.on_tap then self.on_tap() end
      self.redraw_fn()
    end
  end
  return true
end

--- Is a canvas point on the button (its track included)?
function LongPressButton:hit(x, y)
  return x >= self.x and x <= self.x + self.width and y >= self.y - 1 and y <= self.y + self.height + 3
end

--- Pass touch presses through (canvas units). Returns true if the press landed on the button.
function LongPressButton:press(x, y)
  if not self:hit(x, y) then return false end
  self:start("touch")
  return true
end

--- Pass touch releases through. Returns true if it ended a touch hold on this button.
function LongPressButton:release(x, y)
  local h = self.held
  if not h or h.by ~= "touch" then return false end
  self.held = nil
  self.redraw_fn()
  return true
end

function LongPressButton:redraw()
  local c = key_colour(self.btkey)
  local on = self.is_on()
  local x, y, wd, ht = self.x, self.y, self.width, self.height
  if on then
    screen.aa(1)
    hex(dimmed(c, 0.75))
    screen.rect(x, y, wd, ht)
    screen.fill()
  end
  hex(on and c or dimmed(c, 0.35))
  screen.font_face(self.font_face)
  screen.font_size(self.font_size)
  screen.move(x + wd / 2, y + ht - 1.5)
  screen.text_center(self.label)
  screen.font_face(1)
  screen.font_size(8)
  -- the long press track: dim when idle, filling in the key's colour while held
  local ty = y + ht + 0.9
  hex(dimmed(c, 0.7))
  screen.rect(x, ty, wd, 0.9)
  screen.fill()
  local f = self:progress()
  if f and f > 0 then
    hex(c)
    screen.rect(x, ty, wd * f, 0.9)
    screen.fill()
  end
end

return LongPressButton
