RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua" --love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "signal_component"
require "queue"

Test = meta.new_type("Test", function()
    local out = meta.new(Test, {
        property_01 = 1234,
        property_02 = 5678
    })
    rt.add_signal_component(out)
    return out
end)

instance = Test()
instance.signals:connect("notify::property_02", function(self, property)
    println("called ", property)
end)
instance.property_02 = "test"

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
    love.graphics.print(serialize(instance), 400, 300)
end

--- @brief shutdown
function love.quit()
end

::exit::
