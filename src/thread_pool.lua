require "thread"

rt.settings.thread = {}
rt.settings.thread.worker_code = [[
RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
require "common"
require "log"
require "meta"
require "thread"

-- ID = <ID>
meta.assert_number(ID)

message_routine = coroutine.create(function()
    ::loop::
        println("check")
        local message = love.thread.getChannel(1):demand()
        load(message.code)()
        rt.threads.handle_message(message)
    goto loop
end)
coroutine.resume(message_routine)
]]

rt.Thread = meta.new_type("Thread", function(index)
    local out = meta.new(rt.Thread, {
        _native = love.thread.newThread("ID = " .. tostring(index) .. "\n" .. rt.settings.thread.worker_code)
    })
    out._native:start()
    return out
end)
