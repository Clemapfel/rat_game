RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"
require "queue"

Test_t = meta.new_type("Test", function()
    local out = meta.new("Test")
    meta.add_signal(out, "test")
    meta.add_signal(out, "test2")
    meta.allow_notify(out, "test4")
    out.property = 1234
    return out
end)

x = Test_t()
x:add_signal("property")
x:connect_signal("property", function()
    x:set_signal_blocked("property", true)
    x:emit_signal("property")
    x:set_signal_blocked("property", false)
end)
second = x:connect_signal("property", function()
    println("second called")
end)

x.property = 4567
println(x)