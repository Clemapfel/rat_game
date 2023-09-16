-- entry point for JetBrains IDE debugger
function try_connect_emmy_lua_debugger()
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    require('emmy_core').tcpConnect('localhost', 8172)
end
pcall(try_connect_emmy_lua_debugger)

DEBUG_MODE = love == nil
MARGIN_UNIT = 10

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
require "queue"
require "vector"
require "geometry"
require "color"
require "drawable"
require "shape"
require "label"
require "signal_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"
require "allocation_component"
require "layout_manager"
require "image"
require "vertex_shape"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

rt.Font.DEFAULT = rt.load_font("Roboto", "assets/Roboto")
label = rt.Label("regular <b><color>bold</color></b> <i>italic </i><b><i>bolditalic</b></i>")--"regular\n<b>bold</b>\n<i>italic</i>\n<b><i>bolditalic</b></i>")

shape = rt.VertexShape(
    rt.Vector2(50, 50),
    rt.Vector2(50 + 100, 50),
    rt.Vector2(50, 50 + 100),
    rt.Vector2(50 + 100, 50 + 100)
)

image = rt.Image(100, 100)
for x = 0, 100-1 do
    for y = 0, 100-1 do
        local color = rt.HSVA(x / 100, 1, 1, 1)
        image:set_pixel(x, y, rt.hsva_to_rgba(color))
    end
end
texture = rt.Texture(image)
shape:set_texture(texture)
--shape:set_texture_rectangle(rt.AABB(0.25, 0.25, 0.5, 0.5))

--- @brief startup
function love.load()
    love.window.setTitle("rat_game")
end

--- @brief update tick
function love.update()
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    love.graphics.setColor(1, 1, 1, 1)
    shape:draw()

    function show_fps()
        local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
        local w, h = text:getWidth(), text:getHeight()
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