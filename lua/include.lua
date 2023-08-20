RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"

enum = meta.new("Test", {
    x = 1234,
    y = "test",
})

meta.add_signal(x)
meta.add_signal(enum, "test")
enum["test"] = enum
println(enum)