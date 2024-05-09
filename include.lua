do
    local paths = {
        ";?.lua",
        ";common/?.lua",
        ";battle/?.lua",
    }
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. table.concat(paths))
    io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately
end

local major, minor = love.getVersion()
print("Love2D " .. major .. "." .. minor .. " | " .. jit.version)
love.filesystem.setIdentity("rat_game")

-- standard libs
ffi = require "ffi"
utf8 = require "utf8"
bit = require "bit"

require "common"
require "meta"

-- debugger
pcall(function()
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.3/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end)

-- modules
rt = {}
rt.test = {}
rt.math = {}
rt.graphics = {}
rt.settings = {}
rt.physics = {}
rt.battle = {}
rt.random = {}
rt.overworld = {}
rt.settings = {}
rt.settings.margin_unit = 10
meta.make_auto_extend(rt.settings, true)

bt = rt.battle
ow = rt.overworld
for name in range("rt", "bt", "ow") do
    local t = _G[name]
    setmetatable(t, {
        __index = function(self, key)
            error("In " .. name .. ".__index: key `" .. key .. "` does not exist in table `" .. name .. "`")
        end
    })
end

-- includes
require "common.log"
require "common.filesystem"
require "common.config"
require "common.time"

require "common.matrix"
require "common.geometry"
require "common.random"
require "common.easement_functions"
require "common.list"
require "common.set"

require "common.signals"
require "common.input_handler"
require "common.input_controller"
require "common.graphics"
require "common.drawable"
require "common.animation"
require "common.animation_queue"

require "common.color"
require "common.palette"
require "common.image"
require "common.texture"
require "common.render_texture"
require "common.shader"

require "common.shape"
require "common.shape_rectangle"
require "common.shape_polygon"
require "common.shape_ellipse"
require "common.vertex_shape"

require "common.font"
require "common.glyph"
require "common.spline"
require "common.widget"
require "common.snapshot"
require "common.selection_indicator"
require "common.label"
require "common.sprite_atlas"
require "common.sprite"
require "common.aspect_layout"
require "common.frame"
require "common.spacer"
require "common.direction_indicator"
require "common.scrollbar"
require "common.textbox"
require "common.level_bar"
require "common.gradient"

require "common.physics_world"
require "common.collider"

require "common.audio_playback"
require "common.monitored_audio_playback"
require "common.sound_atlas"

-- battle

require "battle.entity"
require "battle.entity_interface"
require "battle.consumable"
require "battle.consumable_interface"
require "battle.status"
require "battle.status_interface"
require "battle.global_status"
require "battle.global_status_interface"
require "battle.equip"
require "battle.equip_interface"
require "battle.move"
require "battle.move_interface"
require "battle.battle"

require "battle.health_bar"
require "battle.speed_value"
require "battle.status_bar_element"
require "battle.status_bar"
require "battle.battle_sprite"
require "battle.enemy_sprite"
require "battle.party_sprite"
require "battle.priority_queue_element"
require "battle.priority_queue"
require "battle.move_selection_item"
require "battle.move_selection"
require "battle.move_info"
require "battle.entity_info"

require "battle.battle_ui"
require "battle.scene"

for folder in range("animations") do
    for _, name in pairs(love.filesystem.getDirectoryItems("battle/" .. folder)) do
        if name ~= "status" and name ~= "move" then
            local path = "battle." .. folder .. "." .. string.gsub(name, "%.lua$", "")
            require(path)
        end
    end
end

