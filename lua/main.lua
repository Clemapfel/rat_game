function try_connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    require('emmy_core').tcpConnect('localhost', 8172)
end
pcall(try_connect_emmy_lua_debugger)

DEBUG_MODE = love == nil
if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
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
require "signal_component"
require "vertex_shape"
require "gamepad_component"
require "keyboard_component"
require "mouse_component"
require "queue"
require "color"
require "geometry"
require "image"
require "animation"
require "drawable"
require "texture"
require "shape"

require "widget"
require "bin_layout"
require "list_layout"
require "overlay_layout"
require "spacer"
require "image_display"
require "label"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

window = rt.BinLayout()
overlay = rt.OverlayLayout()
window:set_child(overlay)

do
    local child = rt.Spacer()
    child:set_minimum_size(100, 100)
    child:set_margin(10)
    overlay:set_base_child(child)
    child:set_color(rt.RGBA(1, 0, 1, 0.25))
end
do
    local child = rt.Spacer()
    child:set_minimum_size(100, 110)
    child:set_horizontal_alignment(rt.Alignment.START)
    child:set_vertical_alignment(rt.Alignment.START)
    overlay:add_overlay(child)
    child:set_color(rt.RGBA(0, 1, 1, 1))
end
do
    local child = rt.Spacer()
    child:set_minimum_size(110, 100)
    child:set_horizontal_alignment(rt.Alignment.END)
    child:set_vertical_alignment(rt.Alignment.END)
    overlay:add_overlay(child)
    child:set_color(rt.RGBA(1, 1, 0, 1))
end

do
    local child = rt.Spacer()
    child:set_minimum_size(110, 100)
    child:set_horizontal_alignment(rt.Alignment.CENTER)
    child:set_vertical_alignment(rt.Alignment.CENTER)
    child:set_expand_vertically(true)
    child:set_expand_vertically(false)
    overlay:add_overlay(child)
    child:set_color(rt.RGBA(0, 1, 0, 1))
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

    love.graphics.setColor(1, 1, 1, 1)

    window:draw()

    function draw_guides()
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local line = rt.Line(0.5 * w, 0, 0.5 * w, h)
        line:draw()
        line = rt.Line(0, 0.5 * h, w, 0.5 * h)
        line:draw()
    end

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