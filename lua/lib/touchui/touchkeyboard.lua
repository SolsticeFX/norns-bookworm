--- Keyboard
-- A Solstice touch keyboard strip (after parhelion's): piano keys across the screen, a finger
-- plays a key, sliding along the strip glides from key to key. Keys light while held, and notes
-- from elsewhere (e.g. MIDI in) can light them too. It can also send what it plays to MIDI.
--
--   local Keyboard = require 'touchui/touchkeyboard'
--   local kb = Keyboard.new{
--     y = 63,                                   -- top edge; x = 0, width = 128 by default
--     octaves = 2, base = 48,                   -- lowest key (a C), MIDI note number
--     on_note_on = function(n, vel) engine.start(n, vel) end,
--     on_note_off = function(n) engine.stop(n) end,
--     enc = 4,                                  -- the encoder that shifts octaves (labels the C)
--   }
--   function press(x, y) if kb:press(x / 6.25, y / 6.25) then return end ... end
--   function drag(x, y) if kb:drag(x / 6.25, y / 6.25) then return end ... end
--   function release(x, y) if kb:release(x / 6.25, y / 6.25) then return end ... end
--   function enc(n, d) if n == 4 then kb:shift(d) end end
--   -- and in redraw(): kb:redraw()
--
-- MIDI out: kb:set_midi(midi.connect(port), channel), or kb:set_midi(nil) to stop. Only notes
-- played on the keys are sent, never ones lit with kb:light (so MIDI in can't loop back out).
-- Coordinates are canvas units (raw touch px / 6.25 on the 128x76 Solstice canvas).

local util = require 'util'
local MusicUtil = require 'musicutil'

local Keyboard = {}
Keyboard.__index = Keyboard

local WHITE_OFF = {0, 2, 4, 5, 7, 9, 11}
local BLACK_AFTER = {[0] = 1, [1] = 3, [3] = 6, [4] = 8, [5] = 10}   -- white index in octave -> black
local FALLBACK = {0xFFFF11, 0xFF1122, 0x11FF22, 0x1122FF}

local function hex(c)
  if screen.hexrgblevel then
    screen.hexrgblevel(c)
  else
    local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
    screen.level(math.floor((r + g + b) / 3 / 17))
  end
end

local function rect(c, x, y, w, h)
  hex(c)
  screen.rect(x, y, w, h)
  screen.fill()
end

-- encoder n's colour, mixed toward white if it's too dark to read on black
local function enc_colour(n)
  local ok, c = pcall(norns.encoders.get_active_color, n)
  if not (ok and type(c) == "number") then c = FALLBACK[n] or 0xF2F2F2 end
  local r, g, b = (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff
  local lum = 0.3 * r + 0.55 * g + 0.15 * b
  if lum >= 110 then return c end
  local k = util.clamp((110 - lum) / 200, 0, 0.6)
  local function mix(v) return math.floor(v + (255 - v) * k) end
  return (mix(r) << 16) | (mix(g) << 8) | mix(b)
end

--- Create a keyboard.
-- @tparam table o x, y, width, height (canvas units; height defaults to the bottom of the screen);
--   octaves (default 2); base (lowest C, default 48); vel (touch velocity 0..1, default 0.75);
--   on_note_on(n, vel); on_note_off(n); enc (octave encoder, for the label colour; nil = no label);
--   midi_out (a midi.connect() device) and midi_ch; redraw (function, or false).
function Keyboard.new(o)
  local k = setmetatable({}, Keyboard)
  k.x, k.y = o.x or 0, o.y or 63
  k.width = o.width or 128
  k.height = o.height or (76 - k.y)
  k.octaves = o.octaves or 2
  k.base = o.base or 48
  k.vel = o.vel or 0.75
  k.on_note_on = o.on_note_on or function() end
  k.on_note_off = o.on_note_off or function() end
  k.enc = o.enc
  k.midi_out, k.midi_ch = o.midi_out, o.midi_ch or 1
  if o.redraw == false then k.redraw_fn = function() end
  else k.redraw_fn = o.redraw or function() if redraw then redraw() end end end
  k.held = {}          -- notes down on the keys
  k.lit = {}           -- notes lit from elsewhere
  k.touch_note = nil
  return k
end

function Keyboard:whites() return 7 * self.octaves end
function Keyboard:key_w() return self.width / self:whites() end

--- The MIDI note under a canvas point (black keys take the top part of the strip).
function Keyboard:note_at(x, y)
  local ww, lx = self:key_w(), x - self.x
  if y < self.y + self.height * 0.62 then
    for i = 0, self:whites() - 1 do
      local b = BLACK_AFTER[i % 7]
      if b and math.abs(lx - (i + 1) * ww) < ww * 0.32 then return self.base + 12 * (i // 7) + b end
    end
  end
  local i = util.clamp(math.floor(lx / ww), 0, self:whites() - 1)
  return self.base + 12 * (i // 7) + WHITE_OFF[i % 7 + 1]
end

function Keyboard:hit(x, y)
  return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height + 2
end

function Keyboard:play(n)
  if self.held[n] then return end
  self.held[n] = true
  self.on_note_on(n, self.vel)
  if self.midi_out then self.midi_out:note_on(n, math.floor(self.vel * 127), self.midi_ch) end
end

function Keyboard:stop(n)
  if not self.held[n] then return end
  self.held[n] = nil
  self.on_note_off(n)
  if self.midi_out then self.midi_out:note_off(n, 0, self.midi_ch) end
end

--- Send what the keys play to MIDI (dev from midi.connect(port); nil stops it).
function Keyboard:set_midi(dev, ch)
  self:all_off()
  self.midi_out = dev
  self.midi_ch = ch or self.midi_ch
end

--- Light (or unlight) a key for a note played elsewhere, e.g. MIDI in. Doesn't play or send it.
function Keyboard:light(n, on)
  self.lit[n] = on and true or nil
end

--- Shift by d octaves (the lowest key stays a C). Lets go of the touched note first.
function Keyboard:shift(d)
  local s = d > 0 and 1 or (d < 0 and -1 or 0)
  self:all_off()
  self.base = util.clamp(self.base + 12 * s, 0, 120 - 12 * self.octaves)
  self.redraw_fn()
end

--- Let go of everything held on the keys.
function Keyboard:all_off()
  for n in pairs(self.held) do self:stop(n) end
  self.touch_note = nil
end

--- Pass touch presses through (canvas units). Returns true if the press landed on the keys.
function Keyboard:press(x, y)
  if not self:hit(x, y) then return false end
  self.touch_note = self:note_at(x, y)
  self:play(self.touch_note)
  self.redraw_fn()
  return true
end

--- Pass drags through: sliding along the strip glides from key to key (a finger that strays
-- a little above the keys keeps its note). Returns true while a key touch is going on.
function Keyboard:drag(x, y)
  local n0 = self.touch_note
  if not n0 then return false end
  local n = (y >= self.y - 4) and self:note_at(x, math.max(y, self.y)) or n0
  if n ~= n0 then
    self:stop(n0)
    self:play(n)
    self.touch_note = n
    self.redraw_fn()
  end
  return true
end

--- Pass releases through. Returns true if it ended a key touch.
function Keyboard:release(x, y)
  local n = self.touch_note
  if not n then return false end
  self.touch_note = nil
  self:stop(n)
  self.redraw_fn()
  return true
end

function Keyboard:redraw()
  local ww, x0, y0, h = self:key_w(), self.x, self.y, self.height
  local bh = h * 0.65
  local function fill(n, black)
    if self.held[n] or self.lit[n] then return black and 0xC8C8C8 or 0xF2F2F2 end
    return black and 0x161616 or 0x3E3E3E
  end
  rect(0x000000, x0, y0 - 1, self.width, h + 3)      -- (+ the panel's extra rows past 76)
  for i = 0, self:whites() - 1 do
    local n = self.base + 12 * (i // 7) + WHITE_OFF[i % 7 + 1]
    rect(fill(n, false), x0 + i * ww + 0.3, y0, ww - 0.6, h + 2)
  end
  for i = 0, self:whites() - 1 do
    local b = BLACK_AFTER[i % 7]
    if b then
      local n = self.base + 12 * (i // 7) + b
      local bx = x0 + (i + 1) * ww
      rect(0x000000, bx - ww * 0.36, y0, ww * 0.72, bh + 0.6)
      rect(fill(n, true), bx - ww * 0.28, y0, ww * 0.56, bh)
    end
  end
  -- the lowest C's name, in the octave encoder's colour
  if self.enc then
    local b = self.base
    hex((self.held[b] or self.lit[b]) and 0x000000 or enc_colour(self.enc))
    screen.font_face(1)
    screen.font_size(8)
    screen.move(x0 + 1.5, y0 + h - 1.5)
    screen.text(MusicUtil.note_num_to_name(b, true))
  end
end

return Keyboard
