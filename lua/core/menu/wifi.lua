-- SYSTEM > SETTINGS > WIFI
--
-- E2 / tap: choose action     K3 / tap: do it     K2: back
--   OFF/ON   toggle the wifi radio
--   HOTSPOT  start the hotspot (ssid = hostname, password shown on screen)
--   CONNECT  pick a saved network
--   ADD      scan, pick a network, enter password
--   DEL      forget a saved network
--
-- the solstice-wifi service starts the hotspot by itself when no known
-- network is reachable, and switches back when one returns.

local ENC = 2 -- the encoder that drives this page (its colour marks controls)

local listselect = require 'listselect'
local textentry = require 'textentry'

local m = {
  pos = 0,
  actions = {"off", "hotspot", "connect", "add", "del"},
  xp = {0, 20, 58, 94, 114},
  scanning = false,
  pending = nil,   -- message shown until the next status change
  pending_until = 0,
}

m.len = #m.actions

local function now() return util.time() end

local function set_pending(msg)
  m.pending = msg
  m.pending_until = now() + 40
end

local function redraw() if _menu.redraw then _menu.redraw() end end

local function back_here()
  -- listselect/textentry restore our handlers; make sure the screen refreshes
  wifi.update()
  _menu.redraw()
end

----------------------------------------------------------------------
-- actions

m.connect_done = function(x)
  if x ~= "cancel" and m.connect_map[x] then
    local name = m.connect_map[x]
    if name ~= wifi.connection_name then
      set_pending("connecting to " .. name .. "...")
      wifi.connect(name)
    end
  end
  back_here()
end

m.del_done = function(x)
  if x ~= "cancel" and m.connect_map[x] then
    m.del_target = m.connect_map[x]
    listselect.enter({"cancel", "forget " .. m.del_target}, m.del_confirm)
  else
    back_here()
  end
end

m.del_confirm = function(x)
  if x ~= "cancel" and m.del_target then
    wifi.delete(m.del_target)
    set_pending("forgot " .. m.del_target)
  end
  m.del_target = nil
  back_here()
end

local HIDDEN = "[other network...]"

m.add_done = function(x)
  if x == "cancel" then back_here() return end
  if x == HIDDEN then
    textentry.enter(m.hidden_name_done, "", "network name:")
    return
  end
  local e = m.scan_map[x]
  if not e then back_here() return end
  m.try = {ssid = e.ssid, hidden = false}
  if e.secure then
    textentry.enter(m.pass_done, "", e.ssid .. " password:", m.pass_check)
  else
    m.pass_done("")
  end
end

m.hidden_name_done = function(txt)
  if txt == nil or txt == "" then back_here() return end
  m.try = {ssid = txt, hidden = true}
  textentry.enter(m.pass_done, "", "password (blank=open):", m.pass_check_optional)
end

m.pass_check = function(txt)
  if txt == nil then return end
  if #txt < 8 then return "min 8: " .. (8 - #txt)
  elseif #txt > 63 then return "too long" end
end

m.pass_check_optional = function(txt)
  if txt == nil or #txt == 0 then return "open" end
  return m.pass_check(txt)
end

m.pass_done = function(txt)
  if txt ~= nil and m.try then
    local ok = (#txt == 0) or (#txt >= 8 and #txt <= 63)
    if ok then
      set_pending("joining " .. m.try.ssid .. "...")
      wifi.add(m.try.ssid, txt, m.try.hidden)
    else
      set_pending("password must be 8-63 chars")
    end
  end
  m.try = nil
  back_here()
end

local function saved_list()
  local items = {}
  m.connect_map = {}
  for _, name in ipairs(wifi.refresh_connections()) do
    local label = name
    if name == wifi.connection_name then label = "* " .. name end
    m.connect_map[label] = name
    table.insert(items, label)
  end
  return items
end

local function scan_list()
  m.scanning = true
  _menu.redraw()
  local nets = wifi.scan(true)
  if #nets == 0 then nets = wifi.scan(false) end -- rescans can fail in hotspot mode
  m.scanning = false
  local items = {}
  m.scan_map = {}
  for _, e in ipairs(nets) do
    local bars = e.signal >= 70 and "|||" or e.signal >= 45 and "||" or "|"
    local label = e.ssid .. "  " .. bars .. (e.secure and "" or " open")
    if e.active then label = "* " .. label end
    m.scan_map[label] = e
    table.insert(items, label)
  end
  table.insert(items, HIDDEN)
  return items
end

m.activate = function()
  local a = m.actions[m.pos + 1]
  if wifi.busy then return end
  if a == "off" then
    if wifi.radio then
      set_pending("turning wifi off...")
      wifi.off()
    else
      set_pending("turning wifi on...")
      wifi.radio_on()
    end
  elseif a == "hotspot" then
    if wifi.state == 1 and not wifi.fallback then return end
    set_pending("starting hotspot...")
    wifi.hotspot()
  elseif a == "connect" then
    listselect.enter(saved_list(), m.connect_done)
  elseif a == "add" then
    listselect.enter(scan_list(), m.add_done)
  elseif a == "del" then
    listselect.enter(saved_list(), m.del_done)
  end
  redraw()
end

----------------------------------------------------------------------
-- input

m.key = function(n, z)
  if n == 2 and z == 1 then
    _menu.set_page("SETTINGS")
  elseif n == 3 and z == 1 then
    m.activate()
  end
end

m.enc = function(n, delta)
  if n == ENC then
    m.pos = util.clamp(m.pos + delta, 0, m.len - 1)
    _menu.redraw()
  end
end
m.pedalenc = m.enc

-- touch: 800x480 panel showing a 128x80 screen (6.25 x 6 px per pixel)
local SCREEN_H = 80
local ACTION_Y = 72
local function to_screen(x, y)
  return x * 128 / _G.touch_resolution_x, y * SCREEN_H / _G.touch_resolution_y
end

local function action_at(sx)
  for i = m.len, 1, -1 do
    if sx >= m.xp[i] - 3 then return i - 1 end
  end
  return 0
end

m.tap = function(x, y)
  local sx, sy = to_screen(x, y)
  if sy >= ACTION_Y - 12 then
    m.pos = action_at(sx)
    _menu.redraw()
    m.activate()
  end
end

----------------------------------------------------------------------
-- screen

local function label(i)
  local a = m.actions[i]
  if a == "off" and not wifi.radio then return "ON" end
  return string.upper(a)
end

-- colour rule: only things the controls act on (the action row, driven by E2
-- + K3) use the encoder colour; read-only info is neutral white/grey.
local function enc_color(active) norns.encoders.screen_color(ENC, active) end
local function info(bright) screen.level(bright and 15 or 5) end

m.redraw = function()
  screen.clear()
  screen.blend_mode(0)

  if m.scanning then
    info(true)
    screen.move(64, 40)
    screen.text_center("scanning...")
    screen.update()
    return
  end

  -- status line
  screen.move(0, 10)
  info(true)
  screen.text(string.upper(wifi.status))
  if wifi.state == 1 and wifi.fallback then
    info(false)
    screen.text(" (no wifi found)")
  end
  if wifi.signal ~= "" then
    info(false)
    screen.move(126, 10)
    screen.text_right(wifi.signal .. "dBm")
  end

  local function row(y, k, v)
    screen.move(0, y)
    info(false)
    screen.text(k .. " ")
    info(true)
    screen.text(v)
  end
  if wifi.state == 1 then
    row(20, "NAME:", wifi.hotspot_ssid())
    row(30, "PASS:", wifi.hotspot_password())
    row(40, "IP:", wifi.ip)
  else
    if wifi.connection_name ~= "" then row(20, "NETWORK:", wifi.connection_name) end
    if wifi.ip ~= "" then row(30, "IP:", wifi.ip) end
  end

  -- activity / last result
  local msg = wifi.busy and (wifi.busy .. "...") or m.pending
  if msg == nil and wifi.result and wifi.state ~= 1
    and wifi.result ~= "connected: " .. wifi.connection_name
    and wifi.result ~= "wifi on" then
    msg = wifi.result
  end
  if msg then
    info(false)
    screen.move(0, 56)
    screen.text(msg)
  end

  -- actions (E2 selects, K3 / tap activates)
  for i = 1, m.len do
    local l = label(i)
    screen.move(m.xp[i], ACTION_Y)
    if i == m.pos + 1 then
      enc_color(true)
      screen.text(l)
      screen.hexrgblevel(screen.fadedColor(0x33FF99, 0xA0))
      screen.blend_mode(13)
      screen.move(m.xp[i] - 2, ACTION_Y - 7.5)
      screen.rounded_rect(m.xp[i] - 2, ACTION_Y - 7.5, screen.text_extents(l) + 4, 10, 2)
      screen.fill()
      screen.blend_mode(0)
    else
      enc_color(false)
      screen.text(l)
    end
  end

  screen.update()
end

----------------------------------------------------------------------

m.tick = function()
  local before = wifi.status .. wifi.connection_name .. (wifi.busy or "")
  wifi.update()
  local after = wifi.status .. wifi.connection_name .. (wifi.busy or "")
  if m.pending and (before ~= after and not wifi.busy or now() > m.pending_until) then
    m.pending = nil
  end
  if _menu.page == "WIFI" then _menu.redraw() end
end

m.init = function()
  wifi.update()
  _menu.timer.time = 1
  _menu.timer.count = -1
  _menu.timer.event = m.tick
  _menu.timer:start()
end

m.deinit = function()
  _menu.timer:stop()
end

return m
