--- @class rt.Scrollbar
--- @param orientation rt.Orientation
--- @param n_steps Number (or nil)
--- @signal value_changed: (::Scrollbar, value::Number) -> nil
rt.Scrollbar = meta.new_type("Scrollbar", rt.Widget, rt.SignalEmitter, function(orientation, n_steps)
    if meta.is_nil(n_steps) then
        n_steps = 0
    end

    local out = meta.new(rt.Scrollbar, {
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _cursor = rt.Rectangle(0, 0, 1, 1),
        _cursor_outline = rt.Rectangle(0, 0, 1, 1),
        _orientation = orientation,
        _value = 0.5,
        _n_steps = n_steps
    })

    out._base:set_color(rt.Palette.BACKGROUND)
    out._base_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._base_outline:set_is_outline(true)

    out._cursor:set_color(rt.Palette.FOREGROUND)
    out._cursor_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    out._cursor_outline:set_is_outline(true)

    out:signal_add("value_changed")
    out:reformat()
    return out
end)

--- @brief [internal] emit signal and reformat
function rt.Scrollbar:_emit_value_changed()
    self:signal_emit("value_changed", self._value)
    self:reformat()
end

--- @brief
function rt.Scrollbar:set_value(value)
    if value < 0 or value > 1 then
        rt.error("In rt.Scrollbar.set_value: value `" .. tostring(value) .. "` is outside [0, 1]")
    end

    self._value = value
    self:_emit_value_changed()
end

--- @brief
function rt.Scrollbar:get_value()
    return self._value
end

--- @brief
function rt.Scrollbar:scroll_down()
    self._value = self._value + 1 / self._n_steps
    self._value = clamp(self._value, 0, 1)
    self:_emit_value_changed()
end

--- @brief
function rt.Scrollbar:scroll_up()
    self._value = self._value - 1 / self._n_steps
    self._value = clamp(self._value, 0, 1)
    self:_emit_value_changed()
end

--- @brief
function rt.Scrollbar:set_n_steps(n)
    if self._n_steps == n then return end
    self._n_steps = n
    self:reformat()
end

--- @brief
function rt.Scrollbar:get_n_steps()
    return self._n_steps
end

--- @overload rt.Drawable.draw
function rt.Scrollbar:draw()
    if not self:get_is_visible() then return end
    if self:get_is_visible() then
        self._base:draw()
        self._base_outline:draw()
        self._cursor:draw()
        self._cursor_outline:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Scrollbar:size_allocate(x, y, width, height)
    self._base:resize(rt.AABB(x, y, width, height))
    self._base_outline:resize(rt.AABB(x, y, width, height))

    if self._orientation == rt.Orientation.HORIZONTAL then
        local cursor_w = width /  math.max(self._n_steps - 1, 1)
        local cursor_x = math.min(x + self._value * (width - cursor_w), x + width - 2 * cursor_w)
        self._cursor:resize(rt.AABB(cursor_x, y, cursor_w, height))
        self._cursor_outline:resize(rt.AABB(cursor_x, y, cursor_w, height))
    else
        local cursor_h = height / math.max(self._n_steps - 1, 1)
        local cursor_y = math.min(y + self._value * (height - cursor_h), x + height - 2 * cursor_h)
        self._cursor:resize(rt.AABB(x, cursor_y, width, cursor_h))
        self._cursor_outline:resize(rt.AABB(x, cursor_y, width, cursor_h))
    end
end

--- @brief [internal]
function rt.test.scrollbar()
    error("TODO")
end


