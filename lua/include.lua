RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"

rt = {}

require "common"
require "meta"
require "queue"

require "status_config"
require "move_config"
require "entity_config"
require "entity"

rt.NewType = meta.new_type("NewType", function()
    return meta.new(rt.NewType)
end)

rt.NewType.test_f = function()
    println("called")
end

instance = rt.NewType()
instance:test_f()

println(instance.test)