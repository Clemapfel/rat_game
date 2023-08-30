RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"

rt = {}

require "common"
require "meta"
require "queue"
require "action_queue"

require "status_config"
require "move_config"
require "entity_config"
require "entity"

queue = rt.ActionQueue()
queue:push(function()
    println("called")
end)
queue:push(function()
    println("called 2")
end)

queue:step()
println("twee")
queue:step()
println("end")