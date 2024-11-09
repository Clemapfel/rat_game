rt.settings.battle.speed_value = {
    font = rt.settings.font.default_mono,
}

--- @class bt.SpeedValue
bt.SpeedValue = meta.new_type("SpeedValue", rt.Widget, function(value)
    if value == nil then value = 0 end
    return meta.new(bt.SpeedValue, {
        _motion_animation = rt.SmoothedMotion1D(value),
        _current_value = value,
        _target_value = value,
        _priority = 0,
        _label = {}
    })
end)

--- @brief
function bt.SpeedValue:_format_value()
    return "<o><b>" .. tostring(math.round(self._current_value)) .. "</o></b>"
end

--- @brief
function bt.SpeedValue:_update_value()
    if self._is_realized then
        self._label:set_text(self:_format_value())
    end
    self:reformat()
end

--- @brief
function bt.SpeedValue:realize()
    if self:already_realized() then return end

    self._label = rt.Label(self:_format_value())
    self._label:set_justify_mode(rt.JustifyMode.LEFT)
    self._label:realize()
    self._motion_animation:set_value(self._current_value)
    self:update(0)
end

--- @override
function bt.SpeedValue:size_allocate(x, y, width, height)
    local label_w, label_h = self._label:measure()
    self._label:fit_into(x + 0.5 * width - 0.5 * label_w, y + 0.5 * height - 0.5 * label_h)
end

--- @override
function bt.SpeedValue:update(delta)
    if self._is_realized ~= true then return end
    self._motion_animation:update(delta)

    local new_value = self._motion_animation:get_value()
    if new_value ~= self._current_value then
        self._current_value = new_value
        self:_update_value()
    end
end
--- @brief
function bt.SpeedValue:set_value(value)
    self._target_value = value
    self._motion_animation:set_target(self._target_value)
end

--- @brief
function bt.SpeedValue:get_value()
    return self._target_value
end

--- @brief
function bt.SpeedValue:skip()
    self._current_value = self._target_value
    self._motion_animation:set_value(self._current_value)
    self:_update_value()
end

--- @brief
function bt.SpeedValue:set_opacity(alpha)
    self._label:set_opacity(alpha)
end

--- @brief
function bt.SpeedValue:draw()
    if self._is_realized == true then
        self._label:draw()
    end
end

--- @override
function bt.SpeedValue:measure()
    return self._label:measure()
end