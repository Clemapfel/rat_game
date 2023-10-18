function try_connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end
pcall(try_connect_emmy_lua_debugger)
io.stdout:setvbuf("no") -- makes it so error message is printed to console immediately

RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "time"
require "vector"
require "angle"
require "random"
require "signal_component"
require "queue"
require "color"
require "palette"
require "geometry"
require "image"
require "animation_timer"
require "drawable"
require "texture"
require "shape"
require "vertex_shape"
require "spritesheet"
require "font"
require "glyph"
require "gamepad_controller"
require "keyboard_controller"
require "mouse_controller"

require "widget"
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
require "animated_sprite"

-- ### MAIN ###

if DEBUG_MODE then goto exit end
rt.Font.DEFAULT = rt.load_font("Roboto", "assets/Roboto")
rt.Font.DEFAULT:set_size(12)

timer = rt.AnimationTimer(1)
timer:set_timing_function(rt.AnimationTimingFunction.LINEAR)
timer:set_should_loop(true)
timer:play()

timer.signal:connect("tick", function(self, t)
    println(t)
end)

window = rt.BinLayout()

clock = rt.Clock()
spritesheet = rt.Spritesheet("art", "orbs")
sprite = rt.Sprite(spritesheet, "orbs")
window:set_child(sprite)

key = rt.add_keyboard_controller(window)
key.signal:connect("key_pressed", function(self, key)

    if key == rt.KeyboardKey.ARROW_UP then
        sprite:set_vertical_alignment(rt.Alignment.START)
    elseif key == rt.KeyboardKey.ARROW_DOWN then
        sprite:set_vertical_alignment(rt.Alignment.END)
    elseif key == rt.KeyboardKey.ARROW_LEFT then
        sprite:set_horizontal_alignment(rt.Alignment.START)
        local frame_i = sprite:get_frame()
        frame_i = clamp(frame_i + 1, 1, sprite:get_n_frames())
        sprite:set_frame(frame_i)
    elseif key == rt.KeyboardKey.ARROW_RIGHT then
        sprite:set_horizontal_alignment(rt.Alignment.END)
        local frame_i = sprite:get_frame()
        frame_i = clamp(frame_i - 1, 1, sprite:get_n_frames())
        sprite:set_frame(frame_i)
    elseif key == rt.KeyboardKey.PLUS then
    elseif key == rt.KeyboardKey.MINUS then
        error("test")
    end
end)

-- @brief window resized
function love.resize(width, height)
    window:fit_into(rt.AABB(0, 0, width, height))
end

--- @brief startup
function love.load()
    love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
        resizable = true
    })
    love.window.setTitle("rat_game")
    window:fit_into(rt.AABB(1, 1, love.graphics.getWidth()-2, love.graphics.getHeight()-2))
end

--- @brief update tick
function love.update()
    rt.AnimationTimerHandler.update(love.timer.getDelta())
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

if DEBUG_MODE then
    println("done.")
end