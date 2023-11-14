RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

require "common"
require "log"
require "meta"
require "thread"

meta.assert_number(rt.get_thread_id())
local out_channel = love.thread.getChannel(-1)
local in_channel = love.thread.getChannel(rt.get_thread_id())

while true do
    ::check_message::
    local message = in_channel:demand()
    meta.assert_enum(message.type, rt.MessageType)

    println("thread #" .. tostring(rt.get_thread_id()) .. " received: ", message.type, " #" .. tostring(message.future_id))

    if message.type == rt.MessageType.LOAD then
        local code = message.code

        local f, parse_error = load(code)
        if meta.is_nil(f) then
            rt.Thread.error(message.future_id, parse_error)
            goto check_message
        end

        local value = {}
        local error_occurred = false
        local error_maybe = nil

        local on_try = function()
            value = f();
            error_occurred = false
        end

        local on_catch = function(err)
            println("[rt][ERROR] In Thread.execute: (" .. tostring(rt.get_thread_id()) .. ") " .. err)
            println("thread #" .. tostring(rt.get_thread_id()) .. " send: ERROR ", error_maybe)
            rt.Thread.error(message.future_id, error_maybe)
        end

        try_catch(on_try, on_catch)

        if error_occurred then
            println("thread #" .. tostring(rt.get_thread_id()) .. " send: ERROR ", error_maybe)
            rt.Thread.error(message.future_id, error_maybe)
        else
            if not meta.is_nil(value) then
                println("thread #" .. tostring(rt.get_thread_id()) .. " send: DELIVER ", serialize(message.future_id))
                rt.Thread.deliver(message.future_id, value)
            end
        end
    elseif message.type == rt.MessageType.INVOKE then
        meta.assert_string(message.function_id)
        meta.assert_table(message.args)
        meta.assert_number(message.future_id)

        local value = {}
        local error_occurred = false
        local error_maybe = nil

        local on_try = function()
            value = _G[message.function_id](table.unpack(message.args))
            error_occurred = false
        end

        local on_catch = function(err)
            println("[rt][ERROR] In Thread.request: (" .. tostring(rt.get_thread_id()) .. ") " .. err)
            error_maybe = err
            error_occurred = true
        end

        try_catch(on_try, on_catch)

        if error_occurred then
            println("thread #" .. tostring(rt.get_thread_id()) .. " send: ERROR ", error_maybe)
            rt.Thread.error(message.future_id, error_maybe)
        else
            println("thread #" .. tostring(rt.get_thread_id()) .. " send: DELIVER #", tostring(message.future_id), " ", serialize(value))
            rt.Thread.deliver(message.future_id, value, error_occurred, error_maybe)
        end
    else
        println("[rt][ERROR] In Thread.main: (" .. tostring(rt.get_thread_id()) .. ") " .. "unhandled message type `" .. message.type .. "`")
    end
end