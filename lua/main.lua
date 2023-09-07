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
require "allocation_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"

instance = meta._new("Object")
rt.AllocationComponent(instance)
rt.GamepadComponent(instance)
rt.KeyboardComponent(instance)
rt.MouseComponent(instance)
rt.SignalComponent(instance)

pos_x, pos_y = 0, 0
animation = rt.Animation(1)
animation:set_timing_function(rt.AnimationTimingFunction.EASE_IN_OUT)
animation.signal:connect("tick", function(self, value)
    local w, h = love.graphics.getPixelDimensions()
    pos_x, pos_y = w * value, h * value
end)
animation:play()

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

    local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
    local w, h = text:getWidth(), text:getHeight()
    love.graphics.translate(love.graphics.getWidth() - w, 0)
    love.graphics.draw(text)
    love.graphics.reset()

    love.graphics.print("test", pos_x, pos_y)
end

--- @brief shutdown
function love.quit()
end

::exit::
