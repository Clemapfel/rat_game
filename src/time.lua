--- @class rt.Time
--- @param microseconds Number
rt.Time = meta.new_type("Time", function(microseconds)
    local out = meta.new(rt.Time, {
        _mys = microseconds
    })
    local metatable = getmetatable(out)
    metatable.__add = function(self, other)


        return rt.Time(self._mys + other._mys)
    end
    metatable.__sub = function(self, other)


        return rt.Time(self._mys - other._mys)
    end
    return out
end)

--- @brief convert to microseconds
--- @return Number
function rt.Time:as_microseconds()

    return self._mys
end

--- @brief convert to milliseconds
--- @return Number
function rt.Time:as_milliseconds()

    return self._mys / 1e3
end

--- @brief convert to seconds
--- @return Number
function rt.Time:as_seconds()

    return self._mys / 1e6
end

--- @brief convert to minutes
--- @return Number
function rt.Time:as_minutes()

    return self._mys / 6e7
end

--- @brief convert to hours
--- @return Number
function rt.Time:as_hours()

    return self._mys / 3.6e+9
end

--- @brief constructor from microseconds
--- @return rt.Time
function rt.microseconds(n)
    return rt.Time(n)
end

--- @brief constructor from milliseconds
--- @return rt.Time
function rt.milliseconds(n)
    return rt.Time(n * 1e3)
end

--- @brief constructor from seconds
--- @return rt.Time
function rt.seconds(n)
    return rt.Time(n * 1e6)
end

--- @brief constructor from minutes
--- @return rt.Time
function rt.minutes(n)
    return rt.Time(n *  6e7)
end

--- @brief constructor from hours
--- @return rt.Time
function rt.hours(n)
    return rt.Time(n * 3.6+9)
end

--- @class rt.Clock
rt.Clock = meta.new_type("Clock", function()
    return meta.new(rt.Clock, {
        _start = love.timer.getTime()
    })
end)

--- @brief get time sinc last restart
--- @return rt.Time
function rt.Clock:get_elapsed()

    return rt.seconds(love.timer.getTime() - self._start)
end

--- @brief restart and return elapsed time
--- @return rt.Time
function rt.Clock:restart()

    local out = love.timer.getTime() - self._start
    self._start = love.timer.getTime()
    return rt.seconds(out)
end

--- @brief [internal] test time
function rt.test.time()
    error("TODO")
end
