RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua" --love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"

rt = {}
rt.test = {}

if love == nil then love = {} end

require "common"
require "meta"
require "queue"
require "geometry"
require "signal_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"

rectangle = rt.Rectangle(12, 14, 100, 200)
println(rectangle:get_top_left())
println(rectangle:contains(12, 14))

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
