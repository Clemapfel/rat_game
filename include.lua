RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}
rt.settings = {}

setmetatable(rt, {
    __index = function(self, key)
        rt.error("In rt.__index: key `" .. key .. "` does not exist in table `rt`")
    end
})

rt.battle = {}
bt = rt.battle

setmetatable(bt, {
    __index = function(self, key)
        rt.error("In bt.__index: key `" .. key .. "` does not exist in table `bt`")
    end
})

math3d = require("submodules/cpml")

require "common"

function connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end
try_catch(connect_emmy_lua_debugger)
io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately

require "profiler"
require "meta"
require "settings"
require "log"

require "time"
require "benchmark"
require "vector"
require "matrix"
require "direction"
require "geometry"
require "angle"
require "random"
require "signals"
require "queue"
require "list"
require "set"
require "color"
require "palette"
require "image"
require "animation_timer"
require "drawable"
require "animation"
require "texture"
require "render_texture"
require "shape"
require "vertex_shape"
require "gradient"
require "shader"
require "render"
require "spritesheet"
require "font"
require "glyph"
require "audio"
require "audio_playback"
require "gamepad_controller"
require "keyboard_controller"
require "mouse_controller"
require "input_controller"
require "thread"

require "widget"
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
require "transition_layout"
require "emblem_layout"
require "level_bar"
require "notch_bar"
require "direction_indicator"
require "swipe_layout"

require "spacer"
require "image_display"
require "label"
require "button"
require "scrollbar"
require "spin_button"
require "switch"
require "scale"
require "viewport"
require "sprite"
require "frame"
require "keymap_indicator"
require "list_view"

require "overworld/snow_effect"
require "overworld/rain_effect"

require "battle/battle_tooltip"

require "battle/action"
require "battle/equipment"
require "battle/status_ailment"
require "battle/entity"

require "battle/entity_portrait"
require "battle/battle_background"
require "battle/equipment_tooltip"
require "battle/equipment_slot"
require "battle/equipment_list_item"
require "battle/action_tooltip"
require "battle/action_list_item"
require "battle/entity_tooltip"
require "battle/status_tooltip"
require "battle/status_thumbnail"
require "battle/stat_level_indicator"
require "battle/stat_level_tooltip"
require "battle/party_info"

require "battle/action_selection_menu"
require "battle/inventory_menu"
require "battle/order_queue"
require "battle/battle_transition"

require "scene"
-- require "test
