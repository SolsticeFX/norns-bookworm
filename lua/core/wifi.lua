--- wifi
-- thin wrapper around NetworkManager (nmcli) and the solstice-wifi helper
-- (/usr/local/bin/solstice-wifi, source in norns/scripts/). anything that
-- changes the connection runs in the background so the UI never blocks;
-- the solstice-wifi service brings up the hotspot when there is no wifi.

local util = require "util"

local HOTSPOT = "Hotspot"
local IFACE = "wlan0"
local HELPER = "/usr/local/bin/solstice-wifi"
local STATE_DIR = "/run/solstice-wifi"
local PASSFILE = "/home/we/norns/.system.hotspot_password"

local function q(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function capture(cmd)
  return util.os_capture(cmd, true) or ""
end

local function lines(s)
  local t = {}
  for line in s:gmatch("([^\n]*)\n?") do
    if line ~= "" then table.insert(t, line) end
  end
  return t
end

-- nmcli --terse escapes ':' and '\' inside values
local function unescape(s)
  return (s:gsub("\\(.)", "%1"))
end

-- split a terse nmcli line into fields, honouring escapes
local function split_terse(line)
  local fields, cur, i = {}, "", 1
  while i <= #line do
    local c = line:sub(i, i)
    if c == "\\" and i < #line then
      cur = cur .. line:sub(i + 1, i + 1); i = i + 2
    elseif c == ":" then
      table.insert(fields, cur); cur = ""; i = i + 1
    else
      cur = cur .. c; i = i + 1
    end
  end
  table.insert(fields, cur)
  return fields
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*l")
  f:close()
  return s
end

local function helper(args)
  local cmd = HELPER .. " " .. args .. " >/dev/null 2>&1 &"
  print("wifi: " .. args)
  os.execute(cmd)
end

local Wifi = {
  -- read by menus (home, looper, wifi)
  status = "unavailable",
  state = 0, -- 0 = OFF/disconnected, 1 = HOTSPOT, 2 = ROUTER (client)
  radio = true,
  ip = "",
  signal = "",
  connection_name = "",
  busy = nil,       -- text while a background action is running
  result = nil,     -- outcome of the last action
  fallback = false, -- hotspot was started automatically

  conn_list = {},
  conn_count = 0,
  conn_active = -1,

  HOTSPOT = HOTSPOT,
}

function Wifi.hotspot_ssid()
  return util.os_capture("hostname") or "norns"
end

function Wifi.hotspot_password()
  local p = read_file(PASSFILE)
  if p == nil or #p < 8 or #p > 63 then p = "nnnnnnnn" end
  return p
end

function Wifi.init()
  Wifi.update()
  print("wifi: " .. Wifi.status .. " " .. Wifi.connection_name .. " " .. Wifi.ip)
end

function Wifi.off() helper("off") end
function Wifi.radio_on() helper("on") end
function Wifi.hotspot() helper("hotspot") end
function Wifi.on(name) helper("connect " .. q(name)) end
Wifi.connect = Wifi.on

function Wifi.add(ssid, psk, hidden)
  local args = "add " .. q(ssid)
  if psk and psk ~= "" then args = args .. " " .. q(psk) end
  if hidden then args = args .. " --hidden" end
  helper(args)
end

function Wifi.delete(name)
  helper("forget " .. q(name))
  for i, n in ipairs(Wifi.conn_list) do
    if n == name then table.remove(Wifi.conn_list, i) break end
  end
  Wifi.conn_count = #Wifi.conn_list
end

function Wifi.ensure_radio_is_on()
  if Wifi.radio_state() ~= "enabled" then Wifi.radio_on() end
end

function Wifi.radio_state()
  return util.os_capture("nmcli --terse radio wifi")
end

--- saved wifi networks (hotspot excluded unless all == true)
function Wifi.connections(all)
  local conns = {}
  for _, line in ipairs(lines(capture("nmcli --terse --fields NAME,TYPE connection show"))) do
    local f = split_terse(line)
    if f[2] == "802-11-wireless" and (all or f[1] ~= HOTSPOT) then
      table.insert(conns, f[1])
    end
  end
  table.sort(conns, function(a, b) return a:lower() < b:lower() end)
  return conns
end

function Wifi.active_connection()
  return Wifi.connection_name ~= "" and Wifi.connection_name or nil
end

--- scan for networks. blocks for a few seconds when rescan is true.
-- returns a list of {ssid=, signal=, secure=, active=}, strongest first,
-- one entry per ssid, hidden networks skipped.
function Wifi.scan(rescan)
  local cmd = "nmcli --terse --fields IN-USE,SIGNAL,SECURITY,SSID device wifi list ifname " .. IFACE
  if rescan then cmd = cmd .. " --rescan yes" end
  local seen, out = {}, {}
  for _, line in ipairs(lines(capture(cmd .. " 2>/dev/null"))) do
    local f = split_terse(line)
    local ssid = f[4]
    if ssid and ssid ~= "" and ssid ~= "--" then
      local sig = tonumber(f[2]) or 0
      local e = seen[ssid]
      if e == nil then
        e = {ssid = ssid, signal = sig, secure = (f[3] ~= "" and f[3] ~= "--"), active = (f[1] == "*")}
        seen[ssid] = e
        table.insert(out, e)
      else
        e.signal = math.max(e.signal, sig)
        e.active = e.active or f[1] == "*"
      end
    end
  end
  table.sort(out, function(a, b) return a.signal > b.signal end)
  return out
end

-- legacy: list of ssid names
function Wifi.ssids()
  local t = {}
  for _, e in ipairs(Wifi.scan(false)) do table.insert(t, e.ssid) end
  return t
end

function Wifi.update()
  Wifi.radio = (Wifi.radio_state() == "enabled")
  Wifi.busy = read_file(STATE_DIR .. "/busy")
  Wifi.result = read_file(STATE_DIR .. "/result")
  Wifi.fallback = util.file_exists(STATE_DIR .. "/fallback")

  local info = {}
  local out = capture("nmcli --terse --fields GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS device show " .. IFACE)
  for _, line in ipairs(lines(out)) do
    local k, v = line:match("^([^:]+):(.*)$")
    if k then info[k] = unescape(v) end
  end

  local code = tonumber((info["GENERAL.STATE"] or ""):match("^(%d+)")) or 0
  local con = info["GENERAL.CONNECTION"] or ""
  local ip = (info["IP4.ADDRESS[1]"] or ""):match("^([^/]+)") or ""

  Wifi.connection_name = con
  Wifi.ip = ""
  Wifi.signal = ""
  Wifi.state = 0

  if not Wifi.radio then
    Wifi.status = "off"
    Wifi.connection_name = ""
  elseif code == 100 then
    Wifi.ip = ip
    if con == HOTSPOT then
      Wifi.state = 1
      Wifi.status = "hotspot"
    else
      Wifi.state = 2
      Wifi.status = "connected"
      local sig = util.os_capture("iw dev " .. IFACE .. " link | awk '/signal/{print $2}'")
      Wifi.signal = sig or ""
    end
  elseif code >= 40 and code < 100 then
    Wifi.status = "connecting"
  elseif code == 30 then
    Wifi.status = "disconnected"
    Wifi.connection_name = ""
  else
    Wifi.status = "unavailable"
    Wifi.connection_name = ""
  end

end

--- refresh the saved-network list (separate from update() to keep polling cheap)
function Wifi.refresh_connections()
  Wifi.conn_list = Wifi.connections()
  Wifi.conn_count = #Wifi.conn_list
  Wifi.conn_active = -1
  for i, n in ipairs(Wifi.conn_list) do
    if n == Wifi.connection_name then Wifi.conn_active = i end
  end
  return Wifi.conn_list
end

return Wifi
