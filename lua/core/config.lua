-- norns configuration

-- add some stuff to package.path
-- this consists of search patterns lua will use for require('foo')

local home = os.getenv('HOME')
local norns = home..'/norns/lua'
local sys = norns..'/?.lua;'
local core = norns..'/core/?.lua;'
local engine = norns..'/engine/?.lua;'
local params = norns..'/core/params/?.lua;'
local lib = norns..'/lib/?.lua;'
local softcut = norns..'/softcut/?.lua;'
local dust = home..'/dust/code/?.lua;'



package.path = sys..core..engine..params..lib..softcut..dust..package.path

-- must be done after package path is set
local tu = require 'tabutil'

_path = {}
_path.home = home
_path.extn = norns..'/extn/'
_path.globallib = norns..'/lib/'
_path.dust = home..'/dust/'
_path.code = _path.dust..'code/'
_path.audio = _path.dust..'audio/'
_path.tape = _path.audio..'tape/'
_path.data = _path.dust..'data/'

--_path.stardust = home..'/stardust/'
--_path.stardustcode = _path.stardust..'code/'
--_path.stardustaudio = _path.stardust..'audio/'
--_path.stardusttape = _path.stardustaudio..'tape/'
--_path.stardustdata = _path.stardust..'data/'

_path.solsticefavorites = _path.data..'system.solsticefavorites'
_path.favorites = _path.data..'system.favorites'
_path.enabled_mods = _path.data..'system.mods'
_path.keyboard_layout = _path.data..'system.kbd_layout'
