UI = require("touchui")

-- create a list of titles

pages = {'Solstice', 'Norns'}


home_tabs = UI.Tabs.new(1,pages)


local tabutil = require "tabutil"
local newpos=0


local m = {
  
  pos = {0,0,0},
  list = {{},{},{}},
  list2 = {},
  listTicker = {0,0,0},
  favorites = {{},{},{}},
  len = "scan",
  alt = false
}

local function menu_table_entry(file)
  local p = string.match(file,".*/")
  local n = string.gsub(file,'.lua','/')
  --if home_tabs.index==1 then
   -- n = string.gsub(n,paths.stardustcode,'')
  --else
    n = string.gsub(n,paths.code,'')
  --end

  
  
  n = string.sub(n,0,-2)
  local a,b = string.match(n,"(.+)/(.+)$") -- strip similar dir/script
  if a==b and a then n = a end
  return {name=n,file=file,path=p}
end

local function sort_select_tree(results)
  if tab.count(m.favorites[home_tabs.index]) > 0 then
    for _, entry in pairs(m.favorites[home_tabs.index]) do
      table.insert(m.list[home_tabs.index],entry)
    end
    table.insert(m.list[home_tabs.index], {name="-", file=nil, path=nil})
  end

  local t = {}
  for filename in results:gmatch("[^\r\n]+") do
    if string.match(filename,"/data/")==nil and
      string.match(filename,"/lib/")==nil and
      string.match(filename,"/solstice/")==nil and
      string.match(filename,"/crow/")==nil then
      table.insert(t,filename)
    end
  end

  for _,file in pairs(t) do
    --print()
    local abspath = menu_table_entry(file).path .. '/solstice/solstice_settings.lua'

    if not util.file_exists(abspath) then
      table.insert(m.list[2],menu_table_entry(file))
    else
      table.insert(m.list[1],menu_table_entry(file))
    end
  end

  m.len = tab.count(m.list[home_tabs.index])
  _menu.redraw()
end

local function contains(list, menu_item)
  for _, v in pairs(list) do
    if v.file == menu_item.file then
      return true
    end
  end
  return false
end

m.init = function()
  
  m.len = "scan"
  m.list[home_tabs.index] = {}
  m.list[home_tabs.index] = {}
  m.favorites[home_tabs.index] = {}
  m.favorites[1] = tabutil.load(paths.solsticefavorites)
  m.favorites[2] = tabutil.load(paths.favorites)
  if m.favorites[home_tabs.index] == nil then
    m.favorites[home_tabs.index] = {}
    tabutil.save(m.favorites[home_tabs.index], paths.favorites)
  end
  -- weird command, but it is fast, recursive, skips hidden dirs, and sorts
 -- if(home_tabs.index==1) then
   -- norns.system_cmd('find ~/stardust/code/ -name "*.lua" | sort', sort_select_tree)
 -- else
    norns.system_cmd('find ~/dust/code/ -name "*.lua" | sort', sort_select_tree)
  --end
  
  m.listTicker[home_tabs.index] = m.pos[home_tabs.index]*(_G.touch_resolution_y/6)
end



m.deinit = norns.none

m.key = function(n,z)
  -- back
  if n == 1 then
    m.alt = z == 1 and true or false
  elseif n==2 and z==1 then
    _menu.set_page("HOME")
    _menu.mode = true

  -- select
  elseif n==3 and z==1 then
    -- return if the current "file" is the split between favorites and all scripts
    if m.list[home_tabs.index][m.pos[home_tabs.index]+1].file == nil then return end
    -- make sure the file still exists
    local previewfile = m.list[home_tabs.index][m.pos[home_tabs.index]+1].file
    if util.file_exists(previewfile) then
      _menu.previewfile = previewfile
      print(previewfile)
      _menu.set_page("PREVIEW")
    else
      m.remove_favorite()
      screen.clear()
      screen.level(15)
      screen.move(64,40)
      screen.text_center("script not found")
      screen.update()
    end
  end
end

m.tap = function(x,y)
  if y<100 then
    if x<400 then
      home_tabs:set_index(1)
      m.redraw()
    else
      home_tabs:set_index(2)
      m.redraw()
    end
    
  else

    local p = math.floor(y*7/(_G.touch_resolution_y)) - 3
    if(p == 0) then
      m.key(3,1)
    end

    m.pos[home_tabs.index] = util.clamp(m.pos[home_tabs.index] + p, 0, m.len - 1)
    m.listTicker[home_tabs.index] = m.pos[home_tabs.index]*(_G.touch_resolution_y/7)
  end
  _menu.redraw()

end

m.drag = function(x,y,sx,sy,lx,ly) 
  m.listTicker[home_tabs.index] = m.listTicker[home_tabs.index] - y + ly
  m.pos[home_tabs.index] = util.clamp(math.floor(m.listTicker[home_tabs.index]*7/(_G.touch_resolution_y)), 0, m.len - 1)
  _menu.redraw()
end

m.enc = function(n,delta)
  if n==2 then
    delta = not m.alt and delta or delta*6

    newpos = util.clamp(m.pos[home_tabs.index]+delta+1, 1,  m.len - 1)
    if ((m.list[home_tabs.index][newpos].name) == '-') then
      delta = delta*2
    end

    m.pos[home_tabs.index] = util.clamp(m.pos[home_tabs.index] + delta, 0, m.len - 1)
    m.listTicker[home_tabs.index] = m.pos[home_tabs.index]*(_G.touch_resolution_y/7)
    _menu.redraw()

  elseif n==3 then
    if delta > 0 then
      m.add_favorite()
    else
      m.remove_favorite()
    end
    _menu.redraw()
  elseif n==1 then
    home_tabs:set_index_delta(delta,false) -- change the index, ie the active tab
    m.init()
    m.redraw()
  end
end

m.redraw = function()
  screen.clear()
  screen.level(15)
  home_tabs:redraw()
  if m.len == "scan" then
    screen.move(64,40)
    screen.text_center("scanning...")
  elseif m.len == 0 then
    screen.move(64,40)
    screen.text_center("no files")
  else
    for i=1,6 do
      if (i > 2 - m.pos[home_tabs.index]) and (i < m.len - m.pos[home_tabs.index] + 3) then
        screen.move(0,10*(i+1))
        local line = m.list[home_tabs.index][i+m.pos[home_tabs.index]-2].name
        if(i==3) then
          screen.rgblevel(15,0,0)
        else
          screen.level(4)
        end
        local is_fave = "  "
        if contains(m.favorites[home_tabs.index], m.list[home_tabs.index][i+m.pos[home_tabs.index]-2]) then is_fave = " * " else is_fave = "   " end

        screen.text(is_fave .. string.upper(line))
      end
    end
  end
  screen.update()
end


m.add_favorite = function()
  -- don't add the '-' split as a favorite.
  if m.list[home_tabs.index][m.pos[home_tabs.index]+1].name == '-' then
    return
  end
  if not contains(m.favorites[home_tabs.index], m.list[home_tabs.index][m.pos[home_tabs.index]+1]) then
    table.insert(m.favorites[home_tabs.index], m.list[home_tabs.index][m.pos[home_tabs.index]+1])
    if(home_tabs.index==1) then
      tabutil.save(m.favorites[home_tabs.index], paths.solsticefavorites)
    else
      tabutil.save(m.favorites[home_tabs.index], paths.favorites)
    end

    
  end
end

m.remove_favorite = function()
  for i, v in pairs(m.favorites[home_tabs.index]) do
    if v.file == m.list[home_tabs.index][m.pos[home_tabs.index]+1].file then
      table.remove(m.favorites[home_tabs.index], i)
      if(home_tabs.index==1) then
        
        tabutil.save(m.favorites[home_tabs.index], paths.solsticefavorites)
      else
        print('regdel')
        tabutil.save(m.favorites[home_tabs.index], paths.favorites)
      end
      return
    end
  end
end

return m
