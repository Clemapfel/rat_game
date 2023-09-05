RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua" --love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "signal_component"
require "queue"
require "keyboard_component"

instance = meta._new("Object")
rt.add_keyboard_component(instance)
instance.keyboard.signals:connect("key_pressed", function(self, key)
    println("Pressed: ", key)
end)
instance.keyboard.signals:connect("key_released", function(self, key)
    println("Released: ", key)
end)
-- ### MAIN ###

if meta.is_nil(love) then goto exit end

--- @brief startup
function love.load()
end

--- @brief update tick
function love.update()
    rt.KeyboardHandler:update()
end

--- @brief draw step
function love.draw()
end

--- @brief shutdown
function love.quit()
end

::exit::
