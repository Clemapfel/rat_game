RESOURCE_PATH = love.filesystem.getSource()
do
    local paths = {
        ";?.lua",
        ";common/?.lua",
        ";battle/?.lua",
    }

    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. table.concat(paths))
        assert(love.filesystem.mountFullPath("/usr/lib64/lua/5.4/", "", "read", true))
    ts = require "tinysplinelua51"
end

local major, minor = love.getVersion()
print("Love2D " .. major .. "." .. minor .. " | " .. jit.version)
love.filesystem.setIdentity("rat_game")

rt = {}
rt.test = {}
rt.math = {}
rt.graphics = {}
rt.settings = {}
rt.physics = {}
rt.battle = {}
rt.overworld = {}

setmetatable(rt, {
    __index = function(self, key)
        rt.error("In rt.__index: key `" .. key .. "` does not exist in table `rt`")
    end
})

bt = rt.battle
rt.battle.Animation = {}
setmetatable(bt, {
    __index = function(self, key)
        rt.error("In bt.__index: key `" .. key .. "` does not exist in table `bt`")
    end
})

ow = rt.overworld
setmetatable(ow, {
    __index = function(self, key)
        rt.error("In ow.__index: key `" .. key .. "` does not exist in table `ow`")
    end
})

-- standard libs
ffi = require "ffi"
utf8 = require "utf8"
bit = require "bit"

-- submodules
math3d = require "submodules.cpml"

require "common"

function connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.3/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end
pcall(connect_emmy_lua_debugger)
io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately

require "meta"
require "settings"
require "log"
require "profiler"

test = meta.new_enum({
    TEST = 1
})

require "config"
require "time"
require "benchmark"
require "thread_pool"
require "vector"
require "matrix"
require "sparse_matrix"
require "direction"
require "geometry"
require "angle"
require "random"
require "statistics"
require "signals"
require "notify"
require "list"
require "set"
require "color"
require "palette"
require "image"
require "graphics"
require "drawable"
require "animation"
require "texture"
require "render_texture"
require "shape"
require "vertex_shape"
require "gradient"
require "shader"
require "render"
require "sprite_atlas"
require "spritesheet"
require "font"
require "glyph"
require "audio"
require "audio_playback"
require "monitored_audio_playback"
require "sound_atlas"
require "easement_functions"
require "spline"
require "bezier_curve"
require "input_handler"
require "input_controller"
require "state_queue"
require "filesystem"


require "widget"

require "plot"
require "snapshot_layout"
require "selection_handler"
require "window_layout"
require "bin_layout"
require "list_layout"
require "overlay_layout"
require "split_layout"
require "grid_layout"
require "flow_layout"
require "aspect_layout"
require "tab_layout"
require "tooltip_layout"
require "emblem_layout"
require "level_bar"
require "notch_bar"
require "direction_indicator"
require "swipe_layout"
require "reveal_layout"

require "spacer"
require "gradient_spacer"
require "image_display"
require "label"
require "button"
require "scrollbar"
require "spin_button"
require "switch"
require "scale"
require "viewport"
require "sprite"
require "particle_emitter"
require "frame"
require "keymap_indicator"
require "list_view"

require "physics_world"
require "collider"
require "joint"

require "battle.stance"
require "battle.move_selection"
require "battle.status"
require "battle.global_status"
require "battle.consumable"
require "battle.equip"
require "battle.move"
require "battle.battle_config"

require "battle.battle_entity"
require "battle.battle_state"
require "battle.battle_animation"
require "battle.health_bar"
require "battle.speed_value"
require "battle.battle_animation_target"

require "battle.battle_background"
require "battle.battle_ui"

-- TODO
for folder in range("animations", "backgrounds") do
    for _, name in pairs(love.filesystem.getDirectoryItems("battle/" .. folder)) do
        if name ~= "status" and name ~= "move" then
            local path = "battle." .. folder .. "." .. string.gsub(name, "%.lua$", "")
            require(path)
        end
    end
end
-- TODO

require "battle.animation_queue"
require "battle.party_info"
require "battle.backdrop"
require "battle.battle_log"
require "battle.priority_queue_element"
require "battle.priority_queue"
require "battle.status_bar_element"
require "battle.status_bar"
require "battle.battle_scene"
require "battle.simulation"

require "battle.interface"
require "battle.global_status_interface"
require "battle.status_interface"
require "battle.consumable_interface"
require "battle.move_interface"
require "battle.equip_interface"

require "battle.enemy_sprite"
require "battle.party_sprite"
require "battle.verbose_info_panel"
require "battle.verbose_info_panel.entity_page"
require "battle.verbose_info_panel.status_page"
require "battle.verbose_info_panel.move_page"

--[[
require "battle.stat"
require "battle.battle_tooltip"
require "battle.action"
require "battle.equipment"
require "battle.status_ailment"
require "battle.entity"

require "battle.entity_portrait"
require "battle.battle_background"
require "battle.equipment_tooltip"
require "battle.equipment_slot"
require "battle.equipment_list_item"
require "battle.action_tooltip"
require "battle.action_list_item"
require "battle.entity_tooltip"
require "battle.status_tooltip"
require "battle.status_thumbnail"
require "battle.stat_level_indicator"
require "battle.stat_level_tooltip"
require "battle.party_info"

require "battle.battle_log"
require "battle.action_selection_menu"
require "battle.inventory_menu"
require "battle.order_queue"
require "battle.battle_transition"
require "battle.enemy_sprite"

for _, name in pairs(love.filesystem.getDirectoryItems("battle/animations")) do
    name = string.sub(name, 1, #name - 4) -- remove `.lua`
    require("battle.animations." .. name)
end
]]--

require "overworld.overworld_entity"
require "overworld.camera"
require "overworld.player"
require "overworld.trigger"
require "overworld.overworld_sprite"
require "overworld.tileset"
require "overworld.stage"

require "scene"
require "overworld.overworld_scene"
--require "battle.battle_scene"


-- require "test


rt.SpriteAtlas = rt.SpriteAtlas()
rt.SpriteAtlas:initialize("assets/sprites")

rt.SoundAtlas = rt.SoundAtlas()
rt.SoundAtlas:initialize("assets/sound_effects")

meta.make_auto_extend(rt.settings, false)