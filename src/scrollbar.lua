--- @class rt.Scrollbar
--- @param orientation rt.Orientation
--- @param n_steps Number (or nil)
--- @signal value_changed: (::Scrollbar, value::Number) -> nil
rt.Scrollbar = meta.new_type("Scrollbar", function(orientation, n_steps)
    meta.assert_enum(orientation, rt.Orientation)

    if meta.is_nil(n_steps) then
        n_steps = 10
    end

    local corner_radius = 10
    local out = meta.new(rt.Scrollbar, {
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _cursor = rt.Rectangle(0, 0, 1, 1, corner_radius),
        _cursor_outline = rt.Rectangle(0, 0, 1, 1, corner_radius),
        _orientation = orientation,
        _value = 0.5,
        _n_steps = n_steps
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)

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
    meta.assert_isa(self, rt.Scrollbar)
    self:signal_emit("value_changed", self._value)
    self:reformat()
end

--- @brief
function rt.Scrollbar:set_value(value)
    meta.assert_number(value)
    meta.assert_isa(self, rt.Scrollbar)

    if value < 0 or value > 1 then
        rt.error("In rt.Scrollbar.set_value: value `" .. tostring(value) .. "` is outside [0, 1]")
    end

    self._value = value
    self:_emit_value_changed()
end

--- @brief
function rt.Scrollbar:get_value()
    meta.assert_isa(self, rt.Scrollbar)
    return self._value
end

--- @brief 
function rt.Scrollbar:scroll_down(offset)
    meta.assert_isa(self, rt.Scrollbar)

    if meta.is_nil(offset) then
        local w, h = self:measure()
        if self._orientation == rt.Orientation.HORIZONTAL then
            offset = 1 / w
        else
            offset = 1 / h
        end
    end
    meta.assert_number(offset)
    
    self._value = self._value + offset
    self._value = clamp(self._value, 0, 1)
    self:_emit_value_changed()
end

--- @brief
function rt.Scrollbar:scroll_up(offset)
    meta.assert_isa(self, rt.Scrollbar)
    if meta.is_nil(offset) then
        local w, h = self:measure()
        if self._orientation == rt.Orientation.HORIZONTAL then
            offset = 1 / w
        else
            offset = 1 / h
        end
    end
    meta.assert_number(offset)

    self._value = self._value - offset
    self._value = clamp(self._value, 0, 1)
    self:_emit_value_changed()
end

--- @overload rt.Drawable.draw
function rt.Scrollbar:draw()
    meta.assert_isa(self, rt.Scrollbar)
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
    meta.assert_isa(self, rt.Scrollbar)
    self._base:resize(rt.AABB(x, y, width, height))
    self._base_outline:resize(rt.AABB(x, y, width, height))

    if self._orientation == rt.Orientation.HORIZONTAL then
        local cursor_w = width / self._n_steps
        local cursor_x = math.min(x + self._value * width, x + width - cursor_w)
        self._cursor:resize(rt.AABB(cursor_x, y, cursor_w, height))
        self._cursor_outline:resize(rt.AABB(cursor_x, y, cursor_w, height))
    else
        local cursor_h = height / self._n_steps
        local cursor_y = math.min(y + self._value * height, x + height - cursor_h)
        self._cursor:resize(rt.AABB(x, cursor_y, width, cursor_h))
        self._cursor_outline:resize(rt.AABB(x, cursor_y, width, cursor_h))
    end
end

--- @brief [internal]
function rt.test.scrollbar()
    error("TODO")
end


