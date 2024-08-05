do
    local paths = {
        ";?.lua",
    }
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. table.concat(paths))
    io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately
end

-- standard libs
ffi = require "ffi"
utf8 = require "utf8"
bit = require "bit"

do -- print versions
    local major, minor = love.getVersion()
    local status
    if jit.status() then
        status = "ON"
    else
        status = "OFF"
    end
    print("Love2D " .. major .. "." .. minor .. " | " .. jit.version .. " (jit: " .. status .. ")")
end

-- other libs
if jit.os == "Linux" then
    fftw3 = ffi.load("fftw3")
elseif jit.os == "Windows" then
    fftw3 = ffi.load("libfftw3-3")
end

require "common.common"
require "common.meta"

-- debugger
pcall(function()
    if love.system.getOS() == "Linux" then
        package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.3/EmmyLua/debugger/emmy/linux/?.so'
    else
        package.cpath = package.cpath .. ';C:/Users/cleme/AppData/Roaming/JetBrains/CLion2023.3/plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
    end
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
rt.random = {}
rt.battle = {}
rt.menu = {}
rt.overworld = {}
rt.settings = {}
rt.settings.margin_unit = 10
meta.make_auto_extend(rt.settings, true)

bt = rt.battle
ow = rt.overworld
mn = rt.menu

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
require "common.graph"

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
require "common.selection_state"
require "common.selection_graph"
require "common.widget"
require "common.snapshot"
require "common.selection_indicator"
require "common.label"
require "common.sprite_atlas"
require "common.sprite"
require "common.aspect_layout"
require "common.frame"
require "common.ordered_box"
require "common.labeled_sprite"
require "common.spacer"
require "common.direction_indicator"
require "common.speech_bubble"
require "common.scrollbar"
require "common.textbox"
require "common.level_bar"
require "common.gradient"
require "common.fast_forward_indicator"
require "common.control_indicator"
require "common.particle_emitter"
require "common.message_dialog"
require "common.keyboard"

require "common.physics_world"
require "common.collider"

require "common.audio_playback"
require "common.monitored_audio_playback"
require "common.sound_atlas"

require "common.scene_state"
require "common.scene"

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
require "battle.battle_interface"

require "battle.health_bar"
require "battle.speed_value"
require "battle.gradient_frame"
require "battle.status_bar"
require "battle.consumable_bar"
require "battle.global_status_bar"
require "battle.battle_sprite"
require "battle.enemy_sprite"
require "battle.party_sprite"
require "battle.priority_queue_element"
require "battle.priority_queue"
require "battle.verbose_info"
require "battle.background"
require "battle.animation"
require "battle.battle_ui"

require "battle.action_choice"
require "battle.enemy_ai"

require "battle.scene_state"
require "battle.scene_state_inspect"
require "battle.scene_state_simulation"
require "battle.move_selection_item"
require "battle.move_selection"
require "battle.scene_state_move_select"
require "battle.scene_state_entity_select"
require "battle.scene_state_manager"

require "battle.scene"
require "battle.simulation_handler"

require "menu.inventory_state"
require "menu.slots"
require "menu.entity_info"
require "menu.scrollable_list"
require "menu.tab_bar"
require "menu.verbose_info_panel"
require "menu.verbose_info_panel_item"
require "menu.object_moved_animation"
require "menu.scene"
