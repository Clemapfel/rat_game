rt.coroutine = {}

--- @class rt.CoroutineStatus
rt.CoroutineStatus = meta.new_enum("CoroutineStatus", {
    IDLE = "normal",
    RUNNING = "running",
    SUSPENDED = "suspended",
    DONE = "dead"
})

do
    local _frame_start = love.timer.getTime()
    local _n_active = 0

    --- @class rt.Coroutine
    rt.Coroutine = meta.new_type("Coroutine", function(coroutine_callback, start_immediately)
        if start_immediately == nil then start_immediately = false end
        local out = meta.new(rt.Coroutine, {
            _native = coroutine.create(function(...)
                _n_active = _n_active + 1
                coroutine_callback(...)
                _n_active = _n_active - 1
            end)
        })

        if start_immediately == true then coroutine.resume(out._native) end
        return out
    end)

    local _get_time = love.timer.getTime
    rt.savepoint_maybe = function(frame_percentage)
        if _n_active <= 0 then return end
        if _get_time() - rt.graphics.frame_start > 2 / 60 then
            coroutine.yield()
        end
    end

end -- do-end

--- @brief
function rt.Coroutine:start(...)
    local status, error = coroutine.resume(self._native, ...)
end

--- @brief
function rt.Coroutine:resume()
    local status, error_maybe = coroutine.resume(self._native)
    if error_maybe ~= nil then
        local stacktrace = debug.traceback(self._native, error_maybe)
        rt.error("In rt.Coroutine:resume:\n" .. stacktrace)
    end
end

--- @brief
rt.savepoint = function()
    coroutine.yield()
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
