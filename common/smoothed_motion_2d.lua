--- @class rt.SmoothedMotion2D
rt.SmoothedMotion2D = meta.new_type("SmoothedMotion2D", function(position_x, position_y, speed)
    meta.assert_number(position_x, position_y, speed)
    return meta.new(rt.SmoothedMotion2D, {
        _speed = speed,
        _current_position_x = position_x,
        _current_position_y = position_y,
        _target_position_x = position_x,
        _target_position_y = position_y,
    })
end)

--- @brief
function rt.SmoothedMotion2D:get_position()
    return self._current_position_x, self._current_position_y
end

--- @brief
function rt.SmoothedMotion2D:set_target_position(x, y)
    self._target_position_x, self._target_position_y = x, y
end

--- @brief
function rt.SmoothedMotion2D:update(delta)
    local distance_x = self._target_position_x - self._current_position_x
    local distance_y = self._target_position_y - self._current_position_y

    local step_x = distance_x * self._speed * delta * delta
    local step_y = distance_y * self._speed * delta * delta

    self._current_position_x = self._current_position_x + step_x
    self._current_position_y = self._current_position_y + step_y

    if  (distance_x > 0 and self._current_position_x > self._target_position_x) or
        (distance_x < 0 and self._current_position_x < self._target_position_x)
    then
        self._current_position_x = self._target_position_x
    end

    if  (distance_y > 0 and self._current_position_y > self._target_position_y) or
        (distance_y < 0 and self._current_position_y < self._target_position_y)
    then
        self._current_position_y = self._target_position_y
    end
end

--- @brief
function rt.SmoothedMotion2D:set_position(x, y)
    self._current_position_x, self._current_position_y = x, y
end

--- @brief
function rt.SmoothedMotion2D:skip()
    self._current_position_x, self._current_position_y = self._current_position_x, self._current_position_y
end