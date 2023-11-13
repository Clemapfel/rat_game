RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

require "common"
require "log"
require "meta"
require "thread"

while true do
    local in_channel = love.thread.getChannel(rt.get_thread_id())
    local out_channel = love.thread.getChannel(-1 * rt.get_thread_id())
    local message = in_channel:demand()
    meta.assert_enum(message.type, rt.MessageType)

    if message.type == rt.MessageType.LOAD then
        local code = message.code
        local f, error = load(code)
        if meta.is_nil(f) then
            rt.warning(error)
        end

        local on_try = function() f() end
        local on_catch = function(err) println("[rt][ERROR] In Thread.execute: (" .. tostring(rt.get_thread_id()) .. ") " .. err) end
        try_catch(on_try, on_catch)
    else
        println("[rt][ERROR] In Thread.execute: (" .. tostring(rt.get_thread_id()) .. ") " .. "unhandled message type `" .. message.type .. "`")
    end
end