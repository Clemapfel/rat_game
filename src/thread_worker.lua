RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
require "common"
require "log"
require "meta"
require "thread"
meta.assert_number(ID)

require "love.timer"

--[[
MessageType     Member      Type        Purpose
LOAD            .code       string      run function thread-side

REQUEST         .name       string      function name
                .args       table       arguments
                .side       number      future ID

DELIVER         .id         number      future ID
                .value      any         returned value
]]--

message_routine = coroutine.create(function()
    local in_channel = rt.threads.get_main_to_worker_channel(ID)
    local out_channel = rt.threads.get_main_to_worker_channel(ID)
    while true do
        message = in_channel:demand()
        meta.assert_message(message)

        if message.type == rt.MessageType.LOAD then
            local __f, error = load(message.code)
            if meta.is_nil(__f) then println(error) end
            try_catch(function()
                __f()
            end, function(err)
                println("[rt][ERROR] In thread #" .. tostring(ID) .. ": ", err)
            end)
        elseif message.type == rt.MessageType.REQUEST then
            meta.assert_string(message.name)
            meta.assert_function(f)
            meta.assert_table(message.args)
            local result = _G[message.name](table.unpack(message.args))
            rt.threads.deliver(ID, message.id, result)
        else
            rt.error("In thread `" .. tostring(ID) .. "` message_routine: unhandled message type `" .. type "`")
        end
        coroutine.yield()
    end
end)

while true do
    coroutine.resume(message_routine)
    love.timer.sleep(1 / 60)
end