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
require "animation"
require "drawable"
require "texture"
require "shape"
require "vertex_shape"
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

-- ### MAIN ###

code = love.filesystem.read("art/orbs.lua")
println(serialize(load(code)()))

if DEBUG_MODE then goto exit end
rt.Font.DEFAULT = rt.load_font("Roboto", "assets/Roboto")
rt.Font.DEFAULT:set_size(12)

window = rt.BinLayout()

label = rt.Label([[
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur at mi vel tellus sagittis ullamcorper nec ut dui. Ut accumsan pulvinar dui, sit amet convallis velit ornare sit amet. Nam eu ligula in velit accumsan semper a a justo. Quisque volutpat risus ut quam ultricies, rutrum varius magna fermentum. Maecenas non eleifend orci. Proin in nibh nulla. Vestibulum vitae vestibulum est, sed ultrices velit. Vivamus purus lorem, condimentum id purus ac, tincidunt euismod nisl. Mauris tempus pharetra augue, a congue sapien mollis at. Sed tristique purus a elit blandit pharetra. Pellentesque ultricies lobortis lobortis. Integer fringilla tempus libero nec tincidunt. Phasellus luctus lorem ut malesuada tincidunt.

Mauris sit amet iaculis nulla. Etiam commodo pulvinar urna, blandit mattis urna iaculis eget. Quisque fermentum massa vitae mauris vulputate, ac faucibus odio sollicitudin. Nullam ornare urna sed nunc cursus egestas. Proin sit amet dictum metus, eu vehicula arcu. Donec mi urna, convallis a commodo nec, varius non diam. Ut at ullamcorper nisi.

Quisque rutrum, arcu a placerat elementum, leo tortor convallis tortor, at consequat felis urna non risus. Nam in leo scelerisque, feugiat nisl vel, hendrerit velit. Quisque sit amet tellus nec nulla tincidunt consectetur. Nullam tellus sem, aliquet vitae mauris sit amet, cursus cursus tortor. Sed facilisis justo sed diam mattis, non gravida dolor tristique. Donec consectetur suscipit arcu, a scelerisque nibh placerat at. Donec nec metus volutpat, suscipit nisi sit amet, rutrum nulla. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec suscipit rutrum sapien in suscipit. Maecenas pretium orci nec aliquet consequat. Etiam luctus est vitae ex elementum, sit amet maximus urna efficitur. Maecenas lacinia, diam ac dictum convallis, est massa gravida ex, nec ornare felis dui vitae libero.")
]])
window:set_child(label)

canvas = rt.RenderTexture(400, 400)

sprite = rt.VertexRectangle(10, 10, 100, 100)
sprite:set_color(rt.RGBA(1, 1, 1, 1))

sprite:set_texture(canvas)
sprite:set_texture_rectangle(rt.AABB(0, 0, 1, 1))

key = rt.add_keyboard_controller(window)
key.signal:connect("key_pressed", function(self, key)

    if key == rt.KeyboardKey.ARROW_UP then
    elseif key == rt.KeyboardKey.ARROW_DOWN then
    elseif key == rt.KeyboardKey.ARROW_LEFT then
    elseif key == rt.KeyboardKey.ARROW_RIGHT then
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
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    love.graphics.setBackgroundColor(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)

    canvas:bind_as_render_target()
    window:draw()
    canvas:unbind_as_render_target()
    sprite:draw()

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
    canvas:unbind_as_render_target()
end

--- @brief shutdown
function love.quit()
    rt.Palette:export("palette.png")
end

::exit::

if DEBUG_MODE then
    println("done.")
end