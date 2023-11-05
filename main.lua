RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}
rt.settings = {}

require "common"
require "meta"
require "time"
require "vector"
require "geometry"
require "angle"
require "random"
require "signals"
require "queue"
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
require "shader"
require "spritesheet"
require "font"
require "glyph"
require "audio"
require "audio_playback"
require "gamepad_controller"
require "keyboard_controller"
require "mouse_controller"

require "widget"
require "window_layout"
require "bin_layout"
require "list_layout"
require "overlay_layout"
require "split_layout"
require "grid_layout"
require "flow_layout"
require "aspect_layout"

require "spacer"
require "image_display"
require "label"
require "scrollbar"
require "viewport"
require "sprite"
require "sprite_frame"
require "sprite_scale"
require "sprite_levelbar"

require "test"

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

-- #############################

rt.Font.DEFAULT_SIZE = 50
rt.Font.DEFAULT = rt.load_font("Roboto", "assets/fonts/Roboto")
rt.Font.DEFAULT_MONO = rt.load_font("DejaVuSansMono", "assets/fonts/DejaVuSansMono")

window = rt.WindowLayout()
spritesheet = rt.Spritesheet("assets/sprites", "test_animation")
sprite = rt.Sprite(spritesheet)
sprite:set_should_loop(true)
sprite:set_is_animated(true)
sprite:set_expand(true)
sprite._shape:set_texture(nil)
sprite:set_color(rt.RGBA(1, 0, 1, 1))

audio = rt.Audio("assets/sound/test_music.mp3")
playback = rt.AudioPlayback(audio)

frame = rt.SpriteFrame(rt.Spritesheet("assets/sprites", "test_frame"))
frame:set_child(sprite)
frame:set_color(rt.Palette.YELLOW)
window:set_child(sprite)

scale_sheet = rt.Spritesheet("assets/sprites", "test_levelbar")
scale = rt.Levelbar(scale_sheet, 0, 1, 0.5, rt.Orientation.HORIZONTAL)
scale:set_expand_vertically(true)
scale:set_expand_horizontally(true)
--scale:set_margin(50)
window:set_child(scale)

key = rt.add_keyboard_controller(window)
key:signal_connect("key_pressed", function(self, key)

    if key == rt.KeyboardKey.ARROW_UP then
    elseif key == rt.KeyboardKey.ARROW_DOWN then
    elseif key == rt.KeyboardKey.ARROW_LEFT then
        scale:set_value(scale:get_value() - 0.05)
    elseif key == rt.KeyboardKey.ARROW_RIGHT then
        scale:set_value(scale:get_value() + 0.05)
    elseif key == rt.KeyboardKey.PLUS then
    elseif key == rt.KeyboardKey.MINUS then
    elseif key == rt.KeyboardKey.SPACE then
        scale:set_orientation(rt.Orientation.HORIZONTAL)
    end
end)

--- @brief startup
function love.load()
    love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
        resizable = true
    })
    love.window.setTitle("rat_game")

    window:realize()
    window:fit_into(rt.AABB(1, 1, love.graphics.getWidth()-2, love.graphics.getHeight()-2))
end

--- @brief update tick
function love.update()
    local delta = love.timer.getDelta()
    if meta.is_nil(delta) then
        println("test")
        return
    end

    rt.AnimationTimerHandler:update(delta)
    rt.AnimationHandler:update(delta)
end

--- @brief draw step
function love.draw()

    love.graphics.setBackgroundColor(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)

    window:draw()

    function draw_guides()
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()

        love.graphics.setColor(0, 1, 1, 0.5)
        local lines = {}
        for _, x in pairs({0.25, 0.5, 0.75, 0.33, 0.66, 0, 1}) do
            table.insert(lines, rt.Line(x * w, 0, x * w, h))
            table.insert(lines, rt.Line(0, x * h, w, x * h))
        end

        local half_color = rt.RGBA(1, 1, 0, 1)
        local third_color = rt.RGBA(0, 1, 1, 1)
        local quarter_color = rt.RGBA(0, 1, 0, 1)
        local outline_color = rt.RGBA(1, 0, 1, 1)

        lines[1]:set_color(quarter_color)
        lines[2]:set_color(quarter_color)
        lines[3]:set_color(half_color)
        lines[4]:set_color(half_color)
        lines[5]:set_color(quarter_color)
        lines[6]:set_color(quarter_color)
        lines[7]:set_color(third_color)
        lines[8]:set_color(third_color)
        lines[9]:set_color(third_color)
        lines[10]:set_color(third_color)
        lines[11]:set_color(outline_color)
        lines[12]:set_color(outline_color)
        lines[13]:set_color(outline_color)
        lines[14]:set_color(outline_color)

        for _, line in pairs(lines) do
            line:draw()
        end
    end
    --draw_guides()

    function show_fps()
        local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
        local w, h = text:getWidth(), text:getHeight()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(text, love.graphics.getWidth() - w, 0)
    end
    show_fps()
end

--- @brief shutdown
function love.quit()
    rt.Palette:export("palette.png")
end

::exit::