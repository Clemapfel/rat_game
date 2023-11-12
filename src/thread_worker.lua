RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
require "common"
require "log"
require "meta"
require "thread"

--[[
MessageType     Member      Type        Purpose
LOAD            .code       string      run function thread-side

REQUEST         .name       string      function name
                .args       table       arguments
                .side       number      future ID

DELIVER         .id         number      future ID
                .value      any         returned value
]]--



require "love.timer"
function test_f(x)
    love.timer.sleep(4)
    return x + 1234
end

-- ID = @out@
message_routine = coroutine.create(function()
    local in_channel = rt.threads.get_main_to_worker_channel(ID)
    local out_channel = rt.threads.get_main_to_worker_channel(ID)
    while true do
        message = in_channel:demand()
        println("received: " .. message.type)
        meta.assert_message(message)
        if message.type == rt.MessageType.LOAD then
            meta.assert_string(message.code)
            local f, error_maybe = load(message.code)
            if meta.is_nil(f) then rt.error(error_maybe) end
            f()
        elseif message.type == rt.MessageType.REQUEST then
            meta.assert_string(message.name)
            local f = _G[message.name]
            meta.assert_function(f)
            meta.assert_table(message.args)
            local result = f(table.unpack(message.args))
            rt.threads.deliver(ID, message.id, result)
        else
            rt.error("In thread `" .. tostring(ID) .. "` message_routine: unhandled message type `" .. type "`")
        end
        coroutine.yield()
    end
end)

while true do
    coroutine.resume(message_routine)
end