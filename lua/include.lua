package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"

x = meta._new("Test")
meta._install_signal(x, "test")
x:connect_signal_test(function(self, abc)
    println(meta.typeof(self), " ", abc)
end)
x:emit_signal_test(1234)
