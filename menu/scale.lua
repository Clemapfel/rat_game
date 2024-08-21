--- @class mn.Scale
--- @signal value_changed (mn.Scale, fraction) -> nil
mn.Scale = meta.new_type("MenuScale", rt.Widget, rt.SignalEmitter, function(min, max, n_steps, initial_value)
    meta.assert_number(min, max, n_steps)
    if initial_value ~= nil then
        meta.assert_number(initial_value)
    else
        initial_value = min + 0.5 * (max - min)
    end

    local out = meta.new(mn.Scale, {
        _rail_center = rt.Rectangle(0, 0, 1, 1),
        _rail_center_outline_top = rt.Line(0, 0, 1, 1),
        _rail_center_outline_bottom = rt.Line(0, 0, 1,1),
        _rail_left = rt.Circle(0, 0, 1),
        _rail_left_outline = rt.Circle(0, 0, 1),
        _rail_right = rt.Circle(0, 0, 1),
        _rail_right_outline = rt.Circle(0, 0, 1),
        _slider_body = rt.Circle(0, 0, 1),
        _slider_outline = rt.Circle(0, 0, 1),

        _min = min,
        _max = max,
        _n_steps = n_steps,
        _step = (max - min) / n_steps,
        _value = initial_value
    })

    out:signal_add("value_changed")
    return out
end)

--- @override
function mn.Scale:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for shape in range(self._rail_center, self._rail_left, self._rail_right) do
        shape:set_color(rt.Palette.BASE)
    end

    for outline in range(
        self._rail_center_outline_top,
        self._rail_center_outline_bottom,
        self._rail_left_outline,
        self._rail_right_outline,
        self._slider_outline
    ) do
        outline:set_color(rt.Palette.BASE_OUTLINE)
        outline:set_is_outline(true)
    end

    self._slider_body:set_color(rt.Palette.FOREGROUND)
    self:_emit_value_changed()
end

--- @override
function mn.Scale:size_allocate(x, y, width, height)
    local slider_r = height / 2
    self._slider_radius = slider_r
    local rail_r = slider_r / 1.5

    for left in range(self._rail_left, self._rail_left_outline) do
        left:resize(x + rail_r, y + 0.5 * height, rail_r)
    end

    for right in range(self._rail_right, self._rail_right_outline) do
        right:resize(x + width - rail_r, y + 0.5 * height, rail_r)
    end

    local rail_x = x + rail_r
    local rail_h = 2 * rail_r
    local rail_w = width - 2 * rail_r

    self._rail_center:resize(rail_x, y + 0.5 * height - rail_r, rail_w, rail_h)
    self._rail_center_outline_top:resize(rail_x, y + 0.5 * height - rail_r, rail_x + rail_w, y + 0.5 * height - rail_r)
    self._rail_center_outline_bottom:resize(rail_x, y + 0.5 * height + rail_r, rail_x + rail_w, y + 0.5 * height + rail_r)

    local fraction = (self._value - self._min) / (self._max - self._min)
    local slider_x = (x + rail_r) + fraction * (width - 2 * rail_r)
    for slider in range(self._slider_body, self._slider_outline) do
        slider:resize(slider_x, y + 0.5 * height, slider_r)
    end
end

--- @override
function mn.Scale:draw()
    self._rail_left:draw()
    self._rail_left_outline:draw()
    self._rail_right:draw()
    self._rail_right_outline:draw()
    self._rail_center:draw()
    self._rail_center_outline_top:draw()
    self._rail_center_outline_bottom:draw()

    self._slider_body:draw()
    self._slider_outline:draw()
end

--- @brief
function mn.Scale:_quantize_value()
    --self._value = clamp(self._value - math.fmod(self._value, self._step), self._min, self._max)
end

--- @brief
function mn.Scale:_emit_value_changed()
    self:signal_emit("value_changed", (self._value - self._min) / (self._max - self._min))
end

--- @brief
function mn.Scale:can_move_right()
    return self._value < self._max
end

--- @brief
function mn.Scale:move_right()
    if self:can_move_right() then
        self._value = self._value + self._step
        self:_quantize_value()
        self:_emit_value_changed()
        self:reformat()
        return true
    else
        return false
    end
end

--- @brief
function mn.Scale:can_move_left()
    return self._value > self._min
end

--- @brief
function mn.Scale:move_left()
    if self:can_move_left() then
        self._value = self._value - self._step
        self:_quantize_value()
        self:_emit_value_changed()
        self:reformat()
        return true
    else
        return false
    end
end

--- @brief
function mn.Scale:set_value(x)
    local before = self._value
    self._value = x
    self:_quantize_value()
    if before ~= self._value then
        self:_emit_value_changed()
        if self._is_realized then
            self:reformat()
        end
    end
end

--- @brief
function mn.Scale:get_min()
    return self._min
end

--- @brief
function mn.Scale:get_max()
    return self._max
end

--- @brief
function mn.Scale:get_value()
    return self._value
end

--- @brief
function mn.Scale:update(delta)
    -- noop
end

--- @override
function mn.Scale:measure()
    return self._bounds.width, self._bounds.height
end