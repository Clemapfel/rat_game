rt.coroutine = {}
rt.coroutine.frame_start = love.timer.getTime()
rt.coroutine.n_active = 0

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
        _native = coroutine.create(function(...)
            rt.coroutine.n_active = rt.coroutine.n_active + 1
            f(...)
            rt.coroutine.n_active = rt.coroutine.n_active - 1
        end)
    })

    if start_immediately == true then coroutine.resume(out._native) end
    return out
end)

--- @brief
function rt.Coroutine:start(...)
    local status, error = coroutine.resume(self._native, ...)
end

--- @brief
function rt.Coroutine:resume()
    local status, error_maybe = coroutine.resume(self._native)
    if error_maybe ~= nil then
        local stacktrace = debug.traceback(self._native, error_maybe)
        rt.error(stacktrace)
    end
end

--- @brief
rt.savepoint = function()
    coroutine.yield()
end

--- @brief
rt.savepoint_maybe = function(frame_percentage)
    if rt.coroutine.n_active <= 0 then return end
    if frame_percentage == nil then frame_percentage = 0.5 end
    local frame_duration = rt.graphics.get_frame_duration() / (1 / rt.graphics.get_target_fps())

    if frame_duration > 2 then
        --rt.log("In rt.savepoint_maybe: Lag frame detected, exceeded frame duration by " .. math.round((frame_duration - 1) * 100) .. "%\n" .. debug.traceback())
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
