RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"
require "queue"

Test_t = meta.new_type("Test", function()
    local out = meta.new("Test")
    meta._initialize_signals(out)
    meta._initialize_notify(out)
    out.property = 1234
    return out
end)

t = {}
t[0] = 1234
t[-1] = 2312
t[2] = 12312

for i, v in pairs(t) do
    println(i, " ", v)
end

x = Test_t()
x:connect_notify("property", function()
    println("first called")
end)
second = x:connect_notify("property", function()
    println("second called")
end)
x:disconnect_notify("property", x:get_notify_handler_ids("property"))
println(x)
x.property = 4567