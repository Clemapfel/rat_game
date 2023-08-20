RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"

properties = {
    x = nil,
    y = nil
}
enum = meta.new("Enum")
enum:connect_signal("notify:x", function()
    -- TODO
end)
meta._get_metatable(enum).notify["x"] = function ()
    println("called")
end
enum.x = 1234
