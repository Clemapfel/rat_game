RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua" --love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

rt = {}
rt.test = {}

if love == nil then love = {} end

require "common"
require "meta"
require "signal_component"
require "queue"
require "keyboard_component"
require "gamepad_component"

instance = meta._new("Object")
instance.keyboard = rt.KeyboardComponent(instance)
instance.keyboard.signal:connect("key_pressed", function(self, key)
    println("Pressed: ", key)
end)
instance.keyboard.signal:connect("key_released", function(self, key)
    println("Released: ", key)
end)


-- ### MAIN ###

if meta.is_nil(love) then love = {} end

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
