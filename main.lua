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
rt.SETTINGS = {}

require "common"
require "meta"
require "time"
require "vector"
require "angle"
require "random"
require "signals"
require "queue"
require "set"
require "color"
require "palette"
require "geometry"
require "image"
require "animation_timer"
require "drawable"
require "animated_drawable"
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

rt.Font.DEFAULT_SIZE = 50
rt.Font.DEFAULT = rt.load_font("Roboto", "assets/fonts/Roboto")
rt.Font.DEFAULT_MONO = rt.load_font("DejaVuSansMono", "assets/fonts/DejaVuSansMono")
window = rt.BinLayout()

label = rt.Label("")
label:set_justify_mode(rt.JustifyMode.LEFT)
label:set_horizontal_alignment(rt.Alignment.CENTER)
label:set_vertical_alignment(rt.Alignment.CENTER)
label:set_font(rt.Font.DEFAULT_MONO)
window:set_child(label)

n_chars = 0
label:set_text("regular <color=RED_1>color</color> <b>bold</b> <i>italics</i> <b><i>bold_italic</i></b> <shake>SHAKE</shake> <wave>WAYWAVE</wave> <color=RED_1><rainbow>RAINBOW</rainbow></color>")


--label:set_text("regular <b><shake>bold</shake></b>||| <i>italics</i><b><i>bold_italic</i></b> <col=PURE_MAGENTA>color</col><b><i><col=BLUE_1>TEST</b>ABC</i>DEF</col>")

key = rt.add_keyboard_controller(window)
key:signal_connect("key_pressed", function(self, key)

    if key == rt.KeyboardKey.ARROW_UP then
    elseif key == rt.KeyboardKey.ARROW_DOWN then
    elseif key == rt.KeyboardKey.ARROW_LEFT then
        n_chars = n_chars - 1
        label:set_n_visible_characters(n_chars)
    elseif key == rt.KeyboardKey.ARROW_RIGHT then
        n_chars = n_chars + 1
        label:set_n_visible_characters(n_chars)
    elseif key == rt.KeyboardKey.PLUS then
    elseif key == rt.KeyboardKey.MINUS then
    elseif key == rt.KeyboardKey.SPACE then
        local current = label:get_justify_mode()
        if current == rt.JustifyMode.LEFT then
            label:set_justify_mode(rt.JustifyMode.CENTER)
        elseif current == rt.JustifyMode.CENTER then
            label:set_justify_mode(rt.JustifyMode.RIGHT)
        elseif current == rt.JustifyMode.RIGHT then
            label:set_justify_mode(rt.JustifyMode.LEFT)
        end
    end
end)

window:realize()

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

if DEBUG_MODE then
    println("done.")
end