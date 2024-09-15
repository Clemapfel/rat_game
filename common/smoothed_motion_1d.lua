--- @class rt.SmoothedMotion1D
rt.SmoothedMotion1D = meta.new_type("SmoothedMotion1D", function(value, damping_to_distance_coefficient)
    if damping_to_distance_coefficient == nil then damping_to_distance_coefficient = 1 end
    return meta.new(rt.SmoothedMotion1D, {
        _damping_factor = damping_to_distance_coefficient,
        _current_value = value,
        _target_value = value
    })
end)

--- @brief
function rt.SmoothedMotion1D:get_value()
    return self._current_value
end

--- @brief
function rt.SmoothedMotion1D:set_target(x)
    self._target_value = x
end

--- @brief
function rt.SmoothedMotion1D:step()
    self._current_value = self._target_value
end

--- @brief
function rt.SmoothedMotion1D:set_value(x)
    self._current_value = x
    self._target_value = x
end