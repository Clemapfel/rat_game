RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"

properties = {
    x = nil,
    y = nil
}
enum = meta.new("Enum")
enum:connect_notify("x", function(self, new_value)
    println(sizeof(self), new_value)
end)
enum.x = 1234