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
do
    local test = 1234
    queue:push(function()
        println(test)
    end)
end

queue:step()
