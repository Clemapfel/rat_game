do
    local paths = {
        ";?.lua",
        ";?.lib"
    }
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. table.concat(paths))
    io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately
end

do -- splash screen until compilation is done
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 1)
    local label = "loading..."
    local font = love.graphics.newFont(50)
    local label_w, label_h = font:getWidth(label), font:getHeight(label)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, screen_w, screen_h)

    local value = 0.3
    love.graphics.setColor(value, value, value, 1)
    love.graphics.print(label, font,
        math.floor(0.5 * screen_w - 0.5 * label_w),
        math.floor(0.5 * screen_h - 0.5 * label_h)
    )
    love.graphics.present()
end

-- standard libs
ffi = require "ffi"
utf8 = require "utf8"
bit = require "bit"

-- foreign libraries
do
    -- load box2d wrapper
    box2d = ffi.load("box2d")
    local cdef = love.filesystem.read("physics/box2d_cdef.h")
    ffi.cdef(cdef)

    -- load enkiTS
    enkiTS = ffi.load("enkiTS")
    cdef = love.filesystem.read("physics/enkits_cdef.h")
    ffi.cdef(cdef)

    -- load fftw3
    if jit.os == "Linux" then
        fftw3 = ffi.load("fftw3")
    elseif jit.os == "Windows" then
        fftw3 = ffi.load("libfftw3-3")
    end

    -- load rtmidi
    rtmidi = ffi.load("rtmidi")
    cdef = love.filesystem.read("midi/rtmidi_cdef.h")
    ffi.cdef(cdef)
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
bt.Animation = {}

ow = rt.overworld
b2 = rt.physics
B2_METER_TO_PIXEL = 100
B2_PIXEL_TO_METER = 1 / B2_METER_TO_PIXEL

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

rt.profiler = require "profiler.profiler"

-- common
require "common.time"
require "common.log"
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
require "common.updatable"
require "common.color"
require "common.palette"
require "common.animation_queue"
require "common.timed_animation"
require "common.image"
require "common.texture"
require "common.render_texture"
require "common.shader"
require "common.compute_shader"
require "common.shape"
require "common.shape_rectangle"
require "common.shape_polygon"
require "common.shape_ellipse"
require "common.vertex_shape"
require "common.spline"
require "common.path"

require "common.translation"
require "common.sound_atlas"
require "common.sound_component"
require "common.widget"
require "common.font"
require "common.selection_state"
require "common.selection_graph"
require "common.label"
require "common.frame"
require "common.spacer"
require "common.sprite_atlas"
require "common.sprite"
require "common.sprite_batch"
require "common.scrollbar"
require "common.keybinding_indicator"
require "common.control_indicator"
require "common.particle_emitter"
require "common.message_dialog"
require "common.keyboard"
require "common.direction_indicator"
require "common.text_box"

require "common.rope"
require "common.cloth"

require "common.loading_screen"
require "common.loading_screen_default"
require "common.loading_screen_shatter"

require "common.scene"
require "common.camera"

-- backgrounds
require "backgrounds.background_implementation"
require "backgrounds.background"
require "backgrounds.background_shader_only"

do -- include all backgrounds
    local prefix = "backgrounds"
    for _, name in pairs(love.filesystem.getDirectoryItems(prefix)) do
        if rt.filesystem.is_file(prefix .. "/" .. name) and string.match(name, "%.lua$") ~= nil then
            local path = prefix .. "/" .. string.gsub(name, "%.lua$", "")
            require(string.gsub(path, "/", "."))
        end
    end
end

-- physics
require "physics.math"
require "physics.world"
require "physics.circle"
require "physics.capsule"
require "physics.segment"
require "physics.polygon"
require "physics.shape"
require "physics.body"
require "physics.joint"

require "common.smoothed_motion_2d"
require "common.smoothed_motion_1d"

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
require "menu.deadzone_visualization_widget"
require "menu.options_scene"
require "menu.keybinding_scene"

-- battle
require "battle.move"
require "battle.equip"
require "battle.consumable"
require "battle.status"
require "battle.global_status"
require "battle.entity"
require "battle.string_formatting"

require "battle.ordered_box"
require "battle.health_bar"
require "battle.speed_value"
require "battle.priority_queue"
require "battle.stunned_particle_animation"
require "battle.entity_sprite"
require "battle.party_sprite"
require "battle.enemy_sprite"
require "battle.quicksave_indicator"

require "battle.battle_animation"

require "battle.battle_scene"
require "battle.simulation_handler"

-- state
require "common.game_state"
require "common.game_state_scene"
require "common.game_state_battle"

