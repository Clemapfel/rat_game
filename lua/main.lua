DEBUG_MODE = love == nil
MARGIN_UNIT = 10

if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
    love = {}
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
require "geometry"
require "signal_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"
require "allocation_component"
require "layout_manager"
require "drawable"

drawable = rt.Drawable()
drawable._allocation:set_position(50, 50)
drawable._allocation:set_size(100, 150)
drawable._allocation:set_margin(10)
drawable._allocation:set_margin_right(20)

bin = rt.Bin()
bin.child = "test"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

--- @brief startup
function love.load()
    love.window.setTitle("rat_game")
    love.graphics.setFont(love.graphics.newFont(12))
end

--- @brief update tick
function love.update()
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    drawable:draw_hitbox()

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