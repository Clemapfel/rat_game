function try_connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    require('emmy_core').tcpConnect('localhost', 8172)
end
pcall(try_connect_emmy_lua_debugger)

DEBUG_MODE = love == nil
if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game"
    love = {}
    love.graphics = {}
    love.graphics.getWidth = function() return 1 end
    love.graphics.getHeight = function() return 1 end
    love.graphics.getFont = function() return {} end
else
    RESOURCE_PATH = love.filesystem.getSource()
end

package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
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

if DEBUG_MODE then goto exit end

window = rt.BinLayout()
box = rt.ListLayout(rt.Orientation.VERTICAL)
overlay = rt.OverlayLayout()
base = rt.Spacer()
base:set_color(rt.RGBA(0.1, 0.9, 0.9))
overlay:set_base_child(base)
overlay:add_overlay(box)

viewport = rt.Viewport()
--viewport:set_child(overlay)

viewport:set_minimum_size(150, 0)

aspect = rt.AspectLayout(1.0)
aspect:set_child(overlay)
window:set_child(aspect)

key = rt.add_keyboard_controller(viewport)
key.signal:connect("key_pressed", function(self, key)
    if key == rt.KeyboardKey.ARROW_UP then
        viewport:translate(0, -10)
    elseif key == rt.KeyboardKey.ARROW_DOWN then
        viewport:translate(0, 10)
    elseif key == rt.KeyboardKey.ARROW_LEFT then
        viewport:translate(-10, 0)
    elseif key == rt.KeyboardKey.ARROW_RIGHT then
        viewport:translate(10, 0)
    elseif key == rt.KeyboardKey.PLUS then
        viewport:rotate(rt.degrees(-10))
        --viewport:scale(1.1)
    elseif key == rt.KeyboardKey.MINUS then
        --viewport:scale(0.9)
        viewport:rotate(rt.degrees(10))
    end
end)

for i = 0, 4 do
    local scrollbar = rt.Scrollbar(rt.Orientation.HORIZONTAL)
    scrollbar:set_margin_vertical(10)
    --[[
    local component = rt.add_keyboard_controller(scrollbar)
    component.signal:connect("key_pressed", function(self, key)
        if key == rt.KeyboardKey.UP_ARROW then
            self.instance:scroll_up(0.01)
        end

        if key == rt.KeyboardKey.DOWN_ARROW then
            self.instance:scroll_down(0.01)
        end
    end)
    ]]--
    box:push_back(scrollbar)
end

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
    love.graphics.setBackgroundColor(0.5, 0, 0.5, 0.5)
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
end

::exit::

if DEBUG_MODE then
    println("done.")
end