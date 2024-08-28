rt.coroutine = {}
rt.coroutine.frame_start = love.timer.getTime()

--- @class rt.CoroutineStatus
rt.CoroutineStatus = meta.new_enum({
    IDLE = "normal",
    RUNNING = "running",
    SUSPENDED = "suspended",
    DONE = "dead"
})

--- @class rt.Coroutine
rt.Coroutine = meta.new_type("Coroutine", function(f, start_immediately)
    if start_immediately == nil then start_immediately = false end
    local out = meta.new(rt.Coroutine, {
        _native = coroutine.create(f)
    })

    if start_immediately == true then coroutine.resume(out._native) end
    return out
end)

--- @brief
function rt.Coroutine:start(...)
    coroutine.resume(self._native, ...)
end

--- @brief
function rt.Coroutine:resume()
    coroutine.resume(self._native)
end

--- @brief
rt.savepoint = function()
    coroutine.yield()
end

--- @brief
rt.savepoint_maybe = function(frame_percentage)
    if frame_percentage == nil then frame_percentage = 0.5 end
    local frame_duration = rt.graphics.get_frame_duration() / (1 / 60)
    if frame_duration > 1 then
        rt.error("")
    end

    if frame_duration > frame_percentage then
        coroutine.yield()
    end
end

--- @brief
function rt.Coroutine:yield()
    rt.savepoint()
end

--- @brief
function rt.Coroutine:yield_maybe(frame_percentage)
    rt.savepoint_maybe(frame_percentage)
end

--- @brief
function rt.Coroutine:get_status()
    return coroutine.status(self._native)
end

--- @brief
function rt.Coroutine:get_is_running()
    return coroutine.status(self._native) == "running"
end

--- @brief
function rt.Coroutine:get_is_done()
    return coroutine.status(self._native) == "dead"
end
