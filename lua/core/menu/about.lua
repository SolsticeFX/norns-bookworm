local util = require "util"
local sysInfo = {}
local moreInfo = {}
local scrollIndex = 1

local m = {}

local function parse_uptime(uptime_str)
    local uptime = { days = 0, hours = 0, minutes = 0 }
    for num, unit in string.gmatch(uptime_str, "(%d+)%s(%a+)") do
      if unit == "day" or unit == "days" then
        uptime.days = num
      elseif unit == "hour" or unit == "hours" then
        uptime.hours = num
      elseif unit == "minute" or unit == "minutes" then
        uptime.minutes = num
      end
    end
    return uptime
  end


  local function os_capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
  end
  

m.init = function()
    -- param to switch between screens
    params:add { type = "option", id = "ascii_art", name = "ASCII Art", options = { "norns", "shield", "hardware", "other" }, default = 1 }

    local uptime_str = os_capture("uptime -p")
    local uptime = parse_uptime(uptime_str)
    local uptime_display = string.format("up %dd %dh %dm", uptime.days, uptime.hours, uptime.minutes)
  
    sysInfo = {
      os_capture("whoami") .. "@" .. os_capture("uname -n"),
      os_capture("hostname -I"),
      uptime_display,
      "pkgs " .. os_capture("dpkg-query -f '.\n' -W | wc -l"),
      "scripts " .. os_capture("ls /home/we/dust/code | wc -l"),
      "disk " .. os_capture([[df -h -t ext4 --output=size,used | awk '{if ($1w != "Size") print $2 "/" $1}']]),
      "res 128x64",
      "ver " .. os_capture("cat ~/version.txt")
    }
  
    moreInfo = {
      -- left side
      "system info: ",
      "disk " .. os_capture([[df -h -t ext4 --output=size,used | awk '{if ($1w != "Size") print $2 "/" $1}']]),
      uptime_display,
      "ker " .. os_capture([[uname -r | cut --delimiter="-" --fields=1]]),
      "res 128x64",
      "pkgs " .. os_capture("dpkg-query -f '.\n' -W | wc -l"),
      "temp " .. norns.temp .. "c",
      -- right side
      "norns info: ",
      "ver " .. os_capture("cat ~/version.txt"),
      os_capture("whoami") .. "@" .. os_capture("uname -n"),
      "wifi: " .. os_capture("iwgetid -r"),
      os_capture("hostname -I"),
      os_capture("ls /home/we/dust/code | wc -l") .. " scripts",
      "/audio " .. os_capture("du -sh /home/we/dust/audio | cut --fields=1")
    }
    _menu.redraw()
end

m.key = function(n,z)
    if n==2 and z==1 then
        _menu.set_page("SYSTEM")
    end

end

m.enc = function(n,delta)
    if n == 2 then
        params:delta("ascii_art", delta)
        _menu.redraw()
      end
end

--m.redraw = redraw()

m.redraw = function()
    screen.clear()
    screen.font_size(5)
    screen.font_face(1)
  
    if params:get("ascii_art") == 1 then
      draw_norns_text()
      norns_ascii()
      display_info()
    elseif params:get("ascii_art") == 2 then
      draw_norns_text()
      shield_ascii()
      display_info()
    elseif params:get("ascii_art") == 3 then
      display_more_info()
    elseif params:get("ascii_art") == 4 then
    hw_info()
    end 
  screen.update()
end


function draw_norns_text()
    screen.level(15)
    screen.move(0, 12)
    screen.text("nnn  ooo rrr nnn   ss")
    screen.move(0, 16)
    screen.text("n  n o o r   n  n  s")
    screen.move(0, 20)
    screen.text("n  n ooo r   n  n ss ")
    screen.font_size(8)
  end
  
function norns_ascii()
    screen.move(3, 30)
    screen.text("+------------+") -- top
    screen.move(4, 36)
    screen.text("|")              -- left side 1
    screen.move(56, 36)
    screen.text("|")              -- right side 1
    screen.move(4, 42)
    screen.text("|")              -- left side 2
    screen.move(56, 42)
    screen.text("|")              -- right side 2
    screen.move(4, 48)
    screen.text("|")              -- left side 3
    screen.move(56, 48)
    screen.text("|")              -- right side 3
    screen.move(4, 54)
    screen.text("|")              -- left side 4
    screen.move(56, 54)
    screen.text("|")              -- right side 4
    screen.move(12, 43)
    screen.text(".___.")          -- screen top
    screen.move(11, 49)
    screen.text("|")              -- screen left
    screen.move(30, 49)
    screen.text("|")              -- screen right
    screen.move(12, 52)
    screen.text(".___.")          -- screen bottom
    screen.move(16, 40)
    screen.text("°")              -- e1
    screen.move(11, 37)
    screen.text(".")              -- k1
    screen.move(39, 49)
    screen.text("° °")            -- e2 and e3
    screen.move(38, 51)
    screen.text(". .")            -- e2 and k3
    screen.move(3, 60)
    screen.text("+------------+") -- bottom
  end
  
function shield_ascii()
    screen.move(11, 30)
    screen.text("+---------+") -- top
    screen.move(43, 37)
    screen.text("°")           -- e1
    screen.move(38, 34)
    screen.text(".")           -- k1
    screen.move(12, 35)
    screen.text("|")           -- left side 1
    screen.move(52, 35)
    screen.text("|")           -- right side 1
    screen.move(12, 41)
    screen.text("|")           -- left side 2
    screen.move(52, 41)
    screen.text("|")           -- right side 2
    screen.move(12, 47)
    screen.text("|")           -- left side 3
    screen.move(52, 47)
    screen.text("|")           -- right side 3
    screen.move(12, 53)
    screen.text("|")           -- left side 4
    screen.move(52, 53)
    screen.text("|")           -- right side 4
    screen.move(12, 59)
    screen.text("|")           -- left side 5
    screen.move(52, 59)
    screen.text("|")           -- right side 5
    screen.move(23, 40)
    screen.text("____")        -- screen top
    screen.move(20, 44)
    screen.text("|")           -- left screen 1
    screen.move(20, 51)
    screen.text("|")           -- left screen 2
    screen.move(44, 44)
    screen.text("|")           -- right screen 1
    screen.move(44, 51)
    screen.text("|")           -- right screen 2
    screen.move(23, 51)
    screen.text("____")        -- screen bottom
    screen.move(35, 60)
    screen.text("° °")         -- e2 and e3
    screen.move(20, 57)
    screen.text(". .")         -- k2 and k3
    screen.move(11, 64)
    screen.text("+---------+") -- bottom
  end
  function display_info()
    local info_start = 69
    for i = scrollIndex, scrollIndex + 8 do
      if sysInfo[i] then
        screen.font_size(8)
        screen.move(info_start, (i - scrollIndex + 1) * 8)
        screen.text(sysInfo[i])
      end
    end
  end
  
function display_more_info()
    local rightStartLine = 1 -- adjust this to the line where right side should start
    for i = 1, 7 do
      if moreInfo[i] then
        screen.font_face(1)
        screen.font_size(8)
        screen.move(0, (i - scrollIndex + 1) * 9)
        screen.text(moreInfo[i])
      end
    end
  end

    
function hw_info()
    local rightStartLine = 1 -- adjust this to the line where right side should start

    for i = 8, #moreInfo do
      if moreInfo[i] then
        screen.font_face(1)
        screen.font_size(8)
        screen.move(69, (i - 7) * 9)
        screen.text(moreInfo[i])
      end
    end
  end
  
m.deinit = norns.none

return m
