if love == nil then -- debug mode
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
    love = {}
else
    RESOURCE_PATH = love.filesystem.getSource()
end

package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

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

instance = meta._new("Object")
rt.AllocationComponent(instance)
rt.GamepadComponent(instance)
rt.KeyboardComponent(instance)
rt.MouseComponent(instance)
rt.SignalComponent(instance)
println(serialize(instance))

-- ### MAIN ###

if meta.is_nil(love) then goto exit end

--- @brief startup
function love.load()
end

--- @brief update tick
function love.update()
end

--- @brief draw step
function love.draw()
end

--- @brief shutdown
function love.quit()
end

::exit::
