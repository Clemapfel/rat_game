RESOURCE_PATH = love.filesystem.getSource()
package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

require "common"
require "log"
require "meta"
require "thread"

meta.assert_number(rt.get_thread_id())
assert(rt.get_thread_id() > 0)
local out_channel = love.thread.getChannel(0)
local in_channel = love.thread.getChannel(rt.get_thread_id())

while true do
    local message = in_channel:demand()
    meta.assert_enum(message.type, rt.MessageType)

    if message.type == rt.MessageType.KILL then
        break
    end

    if message.type == rt.MessageType.LOAD then
        local code = message.code

        local f, parse_error = load(code)
        if meta.is_nil(f) then
            rt.Thread.error(message.future_id, parse_error)
            return
        end

        local value = {}
        local error_occurred = false
        local error_maybe = nil

        local on_try = function()
            value = f();
            error_occurred = false
        end

        local on_catch = function(err)
            rt.Thread.error(message.future_id, err)
        end

        try_catch(on_try, on_catch)

        if error_occurred then
            rt.Thread.error(message.future_id, error_maybe)
        else
            if not meta.is_nil(value) then
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
            rt.Thread.error(message.future_id, err)
            return
        end

        try_catch(on_try, on_catch)

        rt.Thread.deliver(message.future_id, value, error_occurred, error_maybe)

    elseif message.type == rt.MessageType.SET then
        meta.assert_string(message.name)
        if message.is_function then
            local f, parse_error = load(message.value)
            if meta.is_nil(f) then
                rt.Thread.error(message.future_id, parse_error)
                return
            end
            _G[message.name] = f
        elseif message.is_nil then
            _G[message.name] = nil
        else
            _G[message.name] = message.value
        end
    elseif message.type == rt.MessageType.GET then
        meta.assert_string(message.name)

        local value = nil
        local on_try = function()
            value = load("return " .. message.name)()
        end
        local on_catch = function(err)
            rt.Thread.error(-1, err)
        end

        try_catch(on_try, on_catch)
        if meta.is_nil(value) then
            love.thread.getChannel(rt.get_thread_id() + 256):push({
                type = rt.MessageType.RETURN,
                value = nil,
                is_function = false,
                is_nil = true
            })
        elseif meta.is_function(value) then
            love.thread.getChannel(rt.get_thread_id() + 256):push({
                type = rt.MessageType.RETURN,
                value = string.dump(value),
                is_function = true,
                is_nil = false
            })
        else
            love.thread.getChannel(rt.get_thread_id() + 256):push({
                type = rt.MessageType.RETURN,
                value = value,
                is_function = false,
                is_nil = false
            })
        end
    else
        rt.Thread.error(-1, "In Thread.main: (" .. tostring(rt.get_thread_id()) .. ") " .. "unhandled message type `" .. message.type .. "`")
    end
end