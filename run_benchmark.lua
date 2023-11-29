RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "profiler"
require "random"
require "time"
require "benchmark"

TestSuper = meta.new_type("TestSuper", function()
    return meta.new(TestSuper)
end)

for i = 1, 1000 do
    TestSuper[rt.random.string(8)] = rt.random.string(32)
end

TestType = meta.new_type("TestType", function()
    return meta.new(TestType, {}, TestSuper)
end)

li = {}

require "profiler"
profiler.start()

benchmark(function()
    local x = TestType()
end)

profiler.stop()
println(profiler.report())