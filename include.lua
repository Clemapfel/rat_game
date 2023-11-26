RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}
rt.settings = {}

rt.battle = {}
bt = rt.battle


require "common"
require "settings"
require "log"
require "meta"
require "time"
require "vector"
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
require "shape"
require "vertex_shape"
require "gradient"
require "shader"
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
require "levelbar"
require "notch_bar"
require "direction_indicator"

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
require "sprite_frame"
require "sprite_scale"
require "sprite_levelbar"

require "battle/action"
require "battle/equipment"

require "battle/equipment_tooltip"
require "battle/equipment_slot"
require "battle/equipment_list_item"

require "scene"
-- require "test