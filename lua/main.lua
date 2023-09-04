RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua" --love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "notify_component"
require "signal_component"
require "queue"

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
