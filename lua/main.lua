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
require "sprite"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

rt.Font.DEFAULT = rt.load_font("Roboto", "assets/Roboto")
label = rt.Label("regular <b><color>bold</color></b> <i>italic </i><b><i>bolditalic</b></i>")--"regular\n<b>bold</b>\n<i>italic</i>\n<b><i>bolditalic</b></i>")

shape = rt.VertexShape(
    rt.Vector2(50, 50),
    rt.Vector2(50 + 100, 50),
    rt.Vector2(50, 50 + 70),
    rt.Vector2(50 + 100, 50 + 70)
)

shape2 = rt.VertexShape(
    rt.Vector2(50, 50),
    rt.Vector2(50 + 100, 50),
    rt.Vector2(50, 50 + 70),
    rt.Vector2(50 + 100, 50 + 70)
)

image = love.graphics.newImage("assets/favicon.png")
shape._mesh:setTexture(image)
shape2:set_color(rt.RGBA(1, 0, 1, 0.5))

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

    shape2:draw()

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