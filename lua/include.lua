RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"

rt = {}

require "common"
require "meta"
require "queue"

enum = meta.new_enum("Test", {
    a = 1234,
    b = "test",
    y = 9
})

for key, value in pairs(enum) do
    println(key, " => ", value)
end