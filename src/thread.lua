--- @class rt.MessageType
rt.MessageType = meta.new_enum({
    LOAD = "LOAD",          -- master -> thread: cause arbitrary code execution
    INVOKE = "INVOKE",      -- master -> thread: invoke a named function with arguments
    DELIVER = "DELIVER",    -- thread -> master: transmit value thread -> master for future
    ERROR = "ERROR",        -- thread -> master: thread has encountered error, send to master to propagate
    SET = "SET",            -- master -> thread: set a thread-side global with master-side value
    GET = "GET",            -- master -> thread: request thread-side value
    RETURN = "RETURN",      -- thread -> master: send `GET` request thread -> master
    KILL = "KILL"          -- master -> thread: cause termination
})

rt.ThreadPool = meta.new_type("ThreadPool", function()
    local out = meta.new(rt.ThreadPool, {
        _threads = {}, -- thread:get_id() -> thread
        _future_id = 2^16,
        _futures = {} -- future:get_id() -> future
    })
    meta.make_weak(out._futures, false, true)
    return out
end)

--- @class rt.Thread
rt.Thread = meta.new_type("Thread", function(id)
    meta.assert_number(id)
    assert(id > 0)
    if not meta.is_nil(rt.current_scene.thread_pool._threads[id]) then
        rt.error("In Thread(): thread with ID `" .. tostring(id) .. "` already registered")
    end

    -- inject hardcoded thread ID into source
    local code = "rt = {} function rt.get_thread_id() return " .. tostring(id) .. " end\n" .. love.filesystem.read("src/thread_worker.lua")
    local out = meta.new(rt.Thread, {
        _id = id,
        _native = love.thread.newThread(code)
    })

    rt.current_scene.thread_pool._threads[out:get_id()] = out
    out._native:start()
    return out
end)

--- @brief restart the thread with a fresh environment
--- @param wait Boolean
function rt.Thread:restart()
    meta.assert_isa(self, rt.Thread)
    ::try_again::
    local message = love.thread.getChannel(self:get_id()):push({
        type = rt.MessageType.KILL
    })
    self._native:wait()
    assert(not self._native:isRunning())
    self._native:start()
end

--- @brief
function rt.ThreadPool:restart()
    meta.assert_isa(self, rt.ThreadPool)
    for _, thread in pairs(self._thread) do
        thread:restart()
    end
end

--- @brief
function rt.Thread:get_id()
    meta.assert_isa(self, rt.Thread)
    return self._id
end

--- @class rt.Future
rt.Future = meta.new_type("Future", function()
    local out = meta.new(rt.Future, {
        _id = rt.current_scene.thread_pool._future_id,
        _value_delivered = false,
        _value = {}
    }, rt.SignalEmitter)

    out:signal_add("delivered")
    rt.current_scene.thread_pool._future_id = rt.current_scene.thread_pool._future_id + 1
    rt.current_scene.thread_pool._futures[out._id] = out
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
function rt.ThreadPool:update_futures()
    meta.assert_isa(self, rt.ThreadPool)
    local in_channel = love.thread.getChannel(0)
    while in_channel:getCount() > 0 do
        local message = in_channel:pop()
        println("main received: ", message.type, " ", tostring(message.future_id))
        meta.assert_enum(message.type, rt.MessageType)
        if message.type == rt.MessageType.DELIVER then
            meta.assert_number(message.future_id, message.thread_id)
            local future = rt.current_scene.thread_pool._futures[message.future_id]

            if meta.is_nil(future) then
                -- future goes out of scope before delivery
                goto continue
            end

            future._value = message.value
            future._value_delivered = true
            future:signal_emit("delivered", future._value)
            rt.current_scene.thread_pool._futures[message.future_id] = nil
            println("main deliever `" .. serialize(future._value) .. "` to future #" .. tostring(future:get_id()))
        elseif message.type == rt.MessageType.ERROR then
            meta.assert_number(message.thread_id, message.future_id)
            rt.error("In Thread #" .. tostring(message.thread_id) .. ": " .. message.error)
        else
            rt.error("In Thread.main: (" .. tostring(message.thread_id) .. ") " .. "unhandled message type `" .. message.type .. "`")
        end
        ::continue::
    end
end

--- @return rt.Future
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

--- @return rt.Future
function rt.Thread.invoke(self, function_id, ...)
    meta.assert_isa(self, rt.Thread)
    meta.assert_string(function_id)

    local future = rt.Future()
    love.thread.getChannel(self:get_id()):push({
        type = rt.MessageType.INVOKE,
        future_id = future:get_id(),
        function_id = function_id,
        args = {...}
    })
    return future
end

--- @return nil
function rt.Thread.deliver(future_id, value, error_occurred, error)
    meta.assert_number(future_id)

    love.thread.getChannel(0):push({
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

    love.thread.getChannel(0):push({
        type = rt.MessageType.ERROR,
        future_id = future_id,
        thread_id = rt.get_thread_id(),
        error = error_message
    })
end

--- @return nil
function rt.Thread:set(variable_name, value)
    meta.assert_isa(self, rt.Thread)
    meta.assert_string(variable_name)

    if meta.is_nil(value) then
        love.thread.getChannel(self:get_id()):push({
            type = rt.MessageType.SET,
            name = variable_name,
            value = nil,
            is_function = false,
            is_nil = true
        })
    elseif meta.is_function(value) then
        love.thread.getChannel(self:get_id()):push({
            type = rt.MessageType.SET,
            name = variable_name,
            value = string.dump(value),
            is_function = true,
            is_nil = false
        })
    else
        love.thread.getChannel(self:get_id()):push({
            type = rt.MessageType.SET,
            name = variable_name,
            value = value,
            is_function = false,
            is_nil = false
        })
    end
end

--- @return any
function rt.Thread:get(variable_name)
    meta.assert_isa(self, rt.Thread)
    meta.assert_string(variable_name)

    love.thread.getChannel(self:get_id()):push({
        type = rt.MessageType.GET,
        name = variable_name
    })
    local channel = love.thread.getChannel(self:get_id() + 256)
    local message = channel:demand()

    meta.assert_enum(message.type, rt.MessageType)
    assert(message.type == rt.MessageType.RETURN)
    if message.is_function then
        local f, parse_error = load(message.value)
        if meta.is_nil(f) then
            rt.error("In rt.Thread:get: unable to load function from string `" .. message.value .. "`")
        end
        return f
    elseif message.is_nil then
        return nil
    else
        return message.value
    end
end

--- @brief [internal]
if meta.is_nil(rt.test) then rt.test = {} end
function rt.test.thread()
    local ID = 2^32
    local thread = rt.Thread(ID)
    thread._native:start()
    assert(thread:get_id() == ID)

    thread:execute([[
        require "love.timer"
    ]])

    thread:execute(function()
        f = function(x) return x + 1111 end
    end)
    local future = thread:invoke("f", 1234)

    thread:set("test_nil", nil)
    thread:set("test_f", function() return 1234 end)
    thread:set("test_table", {1, 2, 3})

    assert(meta.is_nil(thread:get("test_nil")))
    assert(thread:get("test_f")() == 1234)

    local test_table = thread:get("test_table")
    assert(meta.is_table(test_table) and sizeof(test_table) == 3 and test_table[1] == 1 and test_table[2] == 2 and test_table[3] == 3)

    assert(future:has_value())
    assert(future:get_value() == 1234 + 1111)

    thread:restart()
    for _, var in pairs({"f", "test_nil", "test_f", "test_table"}) do
        assert(meta.is_nil(thread:get(var)))
    end

    -- TODO THESE DEADLOC
end

