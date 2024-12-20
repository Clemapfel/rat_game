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
        _label = {},
        _label_x = 0,
        _label_y = 0,
        _label_w = 0
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
        self._label_w = select(1, self._label:measure())
    end
    self:reformat()
end

--- @brief
function bt.SpeedValue:realize()
    if self:already_realized() then return end

    self._label = rt.Label(self:_format_value())
    self._label:set_justify_mode(rt.JustifyMode.LEFT)
    self._label:realize()
    self._label:fit_into(0, 0)
    self._motion_animation:set_value(self._current_value)
    self:update(0)
end

--- @override
function bt.SpeedValue:size_allocate(x, y, width, height)
    self._label_x = x
    self._label_y = y
end

--- @override
function bt.SpeedValue:update(delta)
    if self._is_realized ~= true then return end
    self._motion_animation:update(delta)

    local new_value = math.ceil(self._motion_animation:get_value())
    if new_value ~= self._current_value then
        self._current_value = new_value
        self:_update_value()
    end
end
--- @brief
function bt.SpeedValue:set_value(value)
    self._target_value = value
    self._motion_animation:set_target_value(self._target_value)
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
        love.graphics.push()
        love.graphics.translate(self._label_x - self._label_w, self._label_y)
        self._label:draw()
        love.graphics.pop()
    end
end

--- @override
function bt.SpeedValue:measure()
    return self._label:measure()
end