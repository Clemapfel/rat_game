--- @class rt.SmoothedMotion1D
rt.SmoothedMotion1D = meta.new_type("SmoothedMotion1D", function(value, speed)
    if speed == nil then speed = 1 end
    return meta.new(rt.SmoothedMotion1D, {
        _speed = speed,
        _current_value = value,
        _target_value = value,
        _last_value = value,
        _elapsed = 0
    })
end)

--- @brief
function rt.SmoothedMotion1D:get_value()
    return self._current_value
end

--- @brief
function rt.SmoothedMotion1D:get_target_value()
    return self._target_value
end

--- @brief
function rt.SmoothedMotion1D:set_target(x)
    self._target_value = x
end

--- @brief
function rt.SmoothedMotion1D:update(delta)
    local diff = math.abs(self._target_value - self._current_value)
    local tick_duration = 1 / 60
    self._elapsed = self._elapsed + delta

    local total_distance = math.abs(self._target_value - self._last_value)
    local current_distance = math.abs(self._current_value - self._last_value)

    local x = current_distance / total_distance
    local min = 0.0
    local distance_factor = 1 + (math.exp(-(4 * (math.pi / 3) * (2 * x - 1)^2)) * (1 - min)) + min
    -- gaussian with peak at x = 0.5, y = 1 and minimum of min

    while self._elapsed > tick_duration do
        local offset = delta * distance_factor * self._speed
        if self._current_value > self._target_value then
            self._current_value = self._current_value - offset
            if self._current_value < self._target_value then
                self._current_value = self._target_value
            end
        elseif self._current_value < self._target_value then
            self._current_value = self._current_value + offset
            if self._current_value > self._target_value then
                self._current_value = self._target_value
            end
        end
        self._elapsed = self._elapsed - tick_duration
    end
end

--- @brief
function rt.SmoothedMotion1D:set_value(x)
    self._last_value = self._current_value
    self._current_value = x
    self._target_value = x
end