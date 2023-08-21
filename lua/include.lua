RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"
require "queue"

mt = {
    __call = function()
        println("called")
    end
}

test = ""
setmetatable(test, mt)

""()