--- @class rt.SmoothedMotion1D
rt.SmoothedMotion1D = meta.new_type("SmoothedMotion1D", function(value, speed)
    if speed == nil then speed = 100 end
    return meta.new(rt.SmoothedMotion1D, {
        _speed = speed,
        _current_value = value,
        _target_value = value,
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
function rt.SmoothedMotion1D:set_target_value(x)
    self._target_value = x
end

--- @brief
function rt.SmoothedMotion1D:update(delta)
    local distance = self._target_value - self._current_value
    if distance < 1 then return end

    local step = 2 * math.ceil(distance) * self._speed * delta * delta

    self._current_value = self._current_value + step
    if  (distance > 0 and self._current_value > self._target_value) or
        (distance < 0 and self._current_value < self._target_value)
    then
        self._current_value = self._target_value
    end

    return self._current_value
end
--- @brief
function rt.SmoothedMotion1D:set_value(x)
    self._last_value = self._target_value
    self._current_value = x
end

--- @brief
function rt.SmoothedMotion1D:skip()
    self:set_value(self._target_value)
end