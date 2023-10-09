--- @class Time
rt.Time = meta.new_type("Time", function(microseconds)
    local out = meta.new(rt.Time, {
        _mys = microseconds
    })
    local metatable = getmetatable(out)
    metatable.__add = function(self, other)
        meta.assert_isa(self, rt.Time)
        meta.assert_isa(other, rt.Time)
        return rt.Time(self._mys + other._mys)
    end
    metatable.__sub = function(self, other)
        meta.assert_isa(self, rt.Time)
        meta.assert_isa(other, rt.Time)
        return rt.Time(self._mys - other._mys)
    end
    return out
end)

--- @brief
function rt.Time:as_microseconds()
    meta.assert_isa(self, rt.Time)
    return self._mys
end

--- @brief
function rt.Time:as_milliseconds()
    meta.assert_isa(self, rt.Time)
    return self._mys / 1e3
end

--- @brief
function rt.Time:as_seconds()
    meta.assert_isa(self, rt.Time)
    return self._mys / 1e6
end

--- @brief
function rt.Time:as_minutes()
    meta.assert_isa(self, rt.Time)
    return self._mys / 6e7
end

--- @brief
function rt.Time:as_hours()
    meta.assert_isa(self, rt.Time)
    return self._mys / 3.6e+9
end

--- @brief
function rt.microseconds(n)
    return rt.Time(n)
end

--- @brief
function rt.milliseconds(n)
    return rt.Time(n * 1e3)
end

--- @brief
function rt.seconds(n)
    return rt.Time(n * 1e6)
end

--- @brief
function rt.minutes(n)
    return rt.Time(n *  6e7)
end

--- @brief
function rt.hours(n)
    return rt.Time(n * 3.6+9)
end

--- @class Clock
rt.Clock = meta.new_type("Clock", function()
    return meta.new(rt.Clock, {
        _start = love.timer.getTime()
    })
end)

--- @brief
function rt.Clock:get_elapsed()
    meta.assert_isa(self, rt.Clock)
    return rt.seconds(love.timer.getTime() - self._start)
end

--- @brief
function rt.Clock:restart()
    meta.assert_isa(self, rt.Clock)
    local out = love.timer.getTime() - self._start
    self._start = love.timer.getTime()
    return rt.seconds(out)
end

--- @brief [internal]
function rt.test.time()
    -- TODO
end
rt.test.time()