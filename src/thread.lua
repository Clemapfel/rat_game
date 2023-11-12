rt.threads = {}
rt.settings.threads = {
    n_threads = 1
}

--- @class rt.MessageType
rt.MessageType = meta.new_enum({
    LOAD = "LOAD",
    REQUEST = "REQUEST",
    DELIVER = "DELIVER"
})

--- @brief
function meta.is_message(object)
    return meta.is_table(object) and meta.is_enum_value(object.type, rt.MessageType)
end

--- @brief
function meta.assert_message(object)
    if not meta.is_message(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Excpected `RGBA`, got `" .. meta.typeof(object) .. "`")
    end
end

rt.threads.future_id = 2^32

--- @class rt.Thread
rt.Thread = meta.new_type("Thread", function(id)
    local out = meta.new(rt.Thread, {
        _id = id,
        _native = {}
    })
    local code = "ID = " .. tostring(out._id) .. "\n" .. love.filesystem.read("src/thread_worker.lua")
    out._native = love.thread.newThread(code)
    out._native:start()
    return out
end)

--- @brief
function rt.Thread:get_id()
    meta.assert_isa(self, rt.Thread)
    return self._id
end

rt.FutureHandler = {}
rt.FutureHandler._futures = {} -- ID -> rt.Future
rt.FutureHandler._threads = {} -- sic, non-weak

for i = 1, rt.settings.threads.n_threads do
    local to_push = rt.Thread(i)
    rt.FutureHandler._threads[to_push:get_id()] = to_push
end

--- @brief access thread from the global thread pool
function rt.get_thread(i)
    meta.assert_number(i)
    local out = rt.FutureHandler._threads[i]
    meta.assert_isa(out, rt.Thread)
    return out
end

--- @brief
function rt.FutureHandler.update_futures()
    for _, thread in pairs(rt.FutureHandler._threads) do
        local channel = rt.threads.get_worker_to_main_channel(thread:get_id())
        assert(meta.is_nil(thread._native:getError()))
        while channel:getCount() > 0 do
            local message = channel:pop()
            meta.assert_message(message)
            if message.type == rt.MessageType.DELIVER then
                local future = rt.FutureHandler._futures[message.id]
                meta.assert_isa(future, rt.Future)
                future._value = message.value
                future._delivered = true
                future:signal_emit("received", future._value)
                rt.FutureHandler._futures[future._id] = nil
            else
                rt.error("In rt.FutureHandler.update_futures: unhandled message type `" .. message.type .. "`")
            end
        end
    end
end

--- @class rt.Future
--- @signal received    (self, any) -> nil
rt.Future = meta.new_type("Future", function()
    local out = meta.new(rt.Future, {
        _id = rt.threads.future_id,
        _value = {},
        _delivered = false
    }, rt.SignalEmitter)
    out:signal_add("received")
    rt.FutureHandler._futures[out._id] = out
    rt.threads.future_id = rt.threads.future_id + 1
    return out
end)

--- @brief
function rt.Future:get_value()
    meta.assert_isa(self, rt.Future)
    return ternary(self._delivered, self._value, nil)
end

--- @brief
function rt.Future:has_value()
    meta.assert_isa(self, rt.Future)
    return self._delivered
end

--- @brief
function rt.Future:get_id()
    meta.assert_isa(self, rt.Future)
    return self._id
end

--- @brief execute arbitrary function thread-side
--- @return nil
function rt.Thread:execute(code)
    meta.assert_isa(self, rt.Thread)
    meta.assert_function(code)
    rt.threads.execute(self._id, code)
    return
end

--- @brief invoke named function thread-side
--- @param function_name String
--- @vararg any (except function)
--- @return rt.Future
function rt.Thread:request(function_name, ...)
    meta.assert_isa(self, rt.Thread)
    meta.assert_string(function_name)
    rt.threads.request(self._id, function_name, ...)
end

--- @brief execute arbitrary code worker-side
function rt.threads.execute(id, code)
    meta.assert_number(id)
    meta.assert_function(code)
    love.thread.getChannel(id):push({
        type = rt.MessageType.LOAD,
        code = string.dump(code)
    })
end

--- @brief send task request from main to worker
function rt.threads.request(thread_id, function_name, ...)
    meta.assert_number(thread_id)
    meta.assert_string(function_name)
    local future = rt.Future()
    rt.threads.get_main_to_worker_channel(thread_id):push({
        type = rt.MessageType.REQUEST,
        id = future:get_id(),
        name = function_name,
        args = {...}
    })
    return future
end

--- @brief send task result from worker to main
function rt.threads.deliver(thread_id, future_id, value)
    meta.assert_number(thread_id, future_id)
    rt.threads.get_worker_to_main_channel(thread_id):push({
        type = rt.MessageType.DELIVER,
        id = future_id,
        value = value
    })
end

--- @brief get worker -> main channel
function rt.threads.get_worker_to_main_channel(id)
    meta.assert_number(id)
    return love.thread.getChannel(tostring(-1 * id))
end

--- @brief get main -> worker channel
function rt.threads.get_main_to_worker_channel(id)
    meta.assert_number(id)
    return love.thread.getChannel(tostring(id))
end
