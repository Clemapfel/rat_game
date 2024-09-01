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

-- other libs
if jit.os == "Linux" then
    fftw3 = ffi.load("fftw3")
elseif jit.os == "Windows" then
    fftw3 = ffi.load("libfftw3-3")
end

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

rt.settings = {}
rt.menu = {}
rt.battle = {}
rt.overworld = {}
rt.physics = {}

mn = rt.menu
bt = rt.battle
ow = rt.overworld
b2 = rt.physics

for _, name in pairs({"rt", "bt", "ow", "b2"}) do
    local t = _G[name]
    setmetatable(t, {
        __index = function(self, key)
            error("In " .. name .. ".__index: key `" .. key .. "` does not exist in table `" .. name .. "`")
        end
    })
end

-- includes

require "common.common"
require "common.serialize"
require "common.meta"
meta.make_auto_extend(rt.settings, true)

-- common
require "common.time"
require "common.log"
require "common.signal_emitter"
require "common.coroutine"
require "common.thread"

require "common.filesystem"
require "common.save_file_handler"
require "common.config"

require "common.geometry"
require "common.random"
require "common.easement_functions"
require "common.set"

require "common.input_button"
require "common.input_controller"

require "common.graphics"
require "common.drawable"
require "common.animation"
require "common.color"
require "common.palette"
require "common.animation_queue"
require "common.image"
require "common.texture"
require "common.render_texture"
require "common.shader"
require "common.shape"
require "common.shape_rectangle"
require "common.shape_polygon"
require "common.shape_ellipse"
require "common.vertex_shape"
require "common.spline"

require "common.text_atlas"
require "common.widget"
require "common.font"
require "common.glyph"
require "common.selection_state"
require "common.selection_graph"
require "common.label"
require "common.frame"
require "common.spacer"
require "common.sprite_atlas"
require "common.sprite"
require "common.labeled_sprite"
require "common.scrollbar"
require "common.keybinding_indicator"
require "common.control_indicator"
require "common.particle_emitter"
require "common.message_dialog"
require "common.keyboard"
require "common.direction_indicator"

require "common.physics_world"
require "common.collider"
require "common.rope"
require "common.cloth"

require "common.scene"

-- battle
require "battle.move"
require "battle.equip"
require "battle.consumable"
require "battle.status"
require "battle.entity"
require "battle.background"

-- menu
require "menu.template"
require "menu.verbose_info_panel"
require "menu.verbose_info_panel_item"
require "menu.tab_bar"
require "menu.scrollable_list"
require "menu.slots"
require "menu.entity_info"
require "menu.inventory_scene_object_moved_animation"
require "menu.inventory_scene"

require "menu.option_button"
require "menu.scale"
require "menu.shake_intensity_widget"
require "menu.msaa_intensity_widget"
require "menu.options_scene"

-- state
require "common.game_state"
require "common.game_state_battle"

