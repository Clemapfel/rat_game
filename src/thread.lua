rt.threads = {}

--- @class rt.MessageType
rt.MessageType = meta.new_enum({
    LOAD = "LOAD",
    INVOKE = "INVOKE",
    DELIVER = "DELIVER",
    ERROR = "ERROR"
})

rt.ThreadPool = {}
rt.ThreadPool._threads = {} -- thread:get_id() -> thread
rt.ThreadPool._future_id = 2^16
rt.ThreadPool._futures = {} -- future:get_id() -> future
meta.make_weak(rt.ThreadPool._futures, false, true)

--- @class rt.Thread
rt.Thread = meta.new_type("Thread", function(id)
    meta.assert_number(id)
    assert(id > 0)
    if not meta.is_nil(rt.ThreadPool._threads[id]) then
        rt.error("In Thread(): thread with ID `" .. tostring(id) .. "` already registered")
    end

    -- inject hardcoded thread ID into source
    local code = "rt = {} function rt.get_thread_id() return " .. tostring(id) .. " end\n" .. love.filesystem.read("src/thread_worker.lua")
    local out = meta.new(rt.Thread, {
        _id = id,
        _native = love.thread.newThread(code)
    })

    rt.ThreadPool._threads[out:get_id()] = out
    out._native:start()
    return out
end)

--- @brief
function rt.Thread:get_id()
    meta.assert_isa(self, rt.Thread)
    return self._id
end

--- @class rt.Future
rt.Future = meta.new_type("Future", function()
    local out = meta.new(rt.Future, {
        _id = rt.ThreadPool._future_id,
        _value_delivered = false,
        _value = {}
    }, rt.SignalEmitter)

    out:signal_add("delivered")
    rt.ThreadPool._future_id = rt.ThreadPool._future_id + 1
    return out
end)

--- @brief
function rt.Future:get_id()
    meta.assert_isa(self, rt.Future)
    return self._id
end

--- @brief
function rt.Future:has_value()
    meta.assert_isa(self, rt.Future)
    return self._value_delivered
end

--- @brief
function rt.Future:get_value()
    meta.assert_isa(self, rt.Future)
    return ternary(self:has_value(), self._value, nil)
end

--- @brief clear the delivery message queue and supply all futures
function rt.ThreadPool.update_futures()
    local in_channel = love.thread.getChannel(-1)
    while in_channel:getCount() > 0 do
        local message = in_channel:pop()
        println("main received: ", message.type)
        meta.assert_enum(message.type, rt.MessageType)
        if message.type == rt.MessageType.DELIVER then
            meta.assert_number(message.future_id, message.thread_id)
            local future = rt.ThreadPool._futures[message.future_id]

            if future == nil then
                goto continue
            end

            future.value = message.value
            future:signal_emit("delivered", future.value)
            rt.ThreadPool._futures[message.future_id] = nil
            println("main deliever `" .. serialize(value) .. "` to future #" .. tostring(future:get_id()))
        elseif message.type == rt.MessageType.ERROR then
            meta.assert_number(message.thread_id, message.future_id)
            rt.error("In Thread #" .. tostring(message.thread_id) .. ": " .. message.error)
        else
            rt.error("In Thread.main: (" .. tostring(message.thread_id) .. ") " .. "unhandled message type `" .. message.type .. "`")
        end
        ::continue::
    end
end

--- @class
function rt.Thread.execute(self, code)
    meta.assert_isa(self, rt.Thread)
    local future = rt.Future()
    if meta.is_string(code) then
        love.thread.getChannel(self:get_id()):push({
            future_id = future:get_id(),
            type = rt.MessageType.LOAD,
            code = code
        })
    else
        meta.assert_function(code)
        love.thread.getChannel(self:get_id()):push({
            future_id = future:get_id(),

            type = rt.MessageType.LOAD,
            code = string.dump(code)
        })
    end
    return future
end

--- @class
function rt.Thread.invoke(self, function_id, ...)
    meta.assert_isa(self, rt.Thread)
    meta.assert_string(function_id)

    local future = rt.Future()
    love.thread.getChannel(self:get_id()):push({
        type = rt.MessageType.REQUEST,
        future_id = future.get_id(),
        function_id = function_id,
        args = {...}
    })

    return future
end

--- @return nil
function rt.Thread.deliver(future_id, value, error_occurred, error)
    meta.assert_number(future_id)

    love.thread.getChannel(-1):push({
        type = rt.MessageType.DELIVER,
        thread_id = rt.get_thread_id(),
        future_id = future_id,
        value = value
    })
end

--- @return nil
function rt.Thread.error(future_id, error_message)
    meta.assert_number(future_id)
    meta.assert_string(error_message)

    love.thread.getChannel(-1):push({
        type = rt.MessageType.ERROR,
        future_id = future_id,
        thread_id = rt.get_thread_id(),
        error = error_message
    })
end

