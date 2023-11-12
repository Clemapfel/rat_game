assert(not meta.is_nil(rt.settings.font.default_size))
rt.settings.scale = {
    slider_radius = rt.settings.font.default_size,
    trough_offset = 8 -- distance between rail and trough
}

--- @class rt.Scale
rt.Scale = meta.new_type("Scale", function(lower, upper, increment, value)
    meta.assert_number(lower, upper, increment)
    value = ternary(meta.is_nil(value), mix(lower, upper, 0.5), value)
    local out = meta.new(rt.Scale, {
        _lower = math.min(lower, upper),
        _upper = math.max(upper, lower),
        _increment = increment,
        _value = value,
        _value_label = rt.Label(tostring(value)),
        _slider = rt.Circle(0, 0, 1, 16),
        _slider_outline = rt.Circle(0, 0, 1),
        _rail_start = rt.Circle(0, 0, 1),
        _rail_start_outline = rt.Circle(0, 0, 1),
        _rail_end = rt.Circle(0, 0, 1),
        _rail_end_outline = rt.Circle(0, 0, 1),
        _rail = rt.Rectangle(0, 0, 1, 1),
        _rail_outline_top = rt.Line(0, 0, 1, 1),
        _rail_outline_bottom = rt.Line(0, 0, 1, 1),
        _trough_start = rt.Circle(0, 0, 1),
        _trough_start_outline = rt.Circle(0, 0, 1),
        _trough_end = rt.Circle(0, 0, 1),
        _trough_end_outline = rt.Circle(0, 0, 1),
        _trough = rt.Rectangle(0, 0, 1, 1),
        _trough_outline_top = rt.Line(0, 0, 1, 1),
        _trough_outline_bottom = rt.Line(0, 0, 1, 1),
        _fill_start = rt.Circle(0, 0, 1),
        _fill_end = rt.Circle(0, 0, 1),
        _fill = rt.Rectangle(0, 0, 1, 1),
        _fill_color = rt.Palette.HIGHLIGHT,
        _show_value = false,
        _value_label = rt.Label(tostring(value)),
        _input = {},
        _mouse = {}
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)

    out._slider:set_color(rt.Palette.FOREGROUND)
    out._slider_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    out._slider_outline:set_is_outline(true)

    for _, rail in pairs({out._rail, out._rail_start, out._rail_end}) do
        rail:set_color(rt.Palette.BASE)
    end

    for _, outline in pairs({
        out._rail_outline_top,
        out._rail_outline_bottom,
        out._rail_start_outline,
        out._rail_end_outline
    }) do
        outline:set_color(rt.Palette.BASE_OUTLINE)
    end
    out._rail_start_outline:set_is_outline(true)
    out._rail_end_outline:set_is_outline(true)

    for _, trough in pairs({out._trough, out._trough_start, out._trough_end}) do
        trough:set_color(rt.Palette.BACKGROUND)
    end

    for _, outline in pairs({
        out._trough_outline_top,
        out._trough_outline_bottom,
        out._trough_start_outline,
        out._trough_end_outline
    }) do
        outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    end
    out._trough_start_outline:set_is_outline(true)
    out._trough_end_outline:set_is_outline(true)

    for _, shape in pairs({out._fill_start, out._fill, out._fill_end}) do
        shape:set_is_visible(true)
    end

    out:set_color(rt.Palette.HIGHLIGHT)

    out:_update_slider()
    out:signal_add("value_changed")

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(controller, button, self)

        local increment = function()
            self:set_value(self:get_value() + self._increment)
        end

        local decrement = function()
            self:set_value(self:get_value() - self._increment)
        end

        if button == rt.InputButton.RIGHT then
            increment()
        elseif button == rt.InputButton.LEFT then
            decrement()
        end

        local x, y = self._input:get_cursor_position()
        local rail_x = select(1, self._rail:get_position())
        local rail_w = select(1, self._rail:get_size())

        if x >= rail_x and x <= rail_x + rail_w then
            self:set_value(self._lower + ((x - rail_x) / rail_w) * (self._upper - self._lower))
        end
    end, out)

    out._input:signal_connect("motion", function(controller, x, y, dx, dy, self)
        if self._input:is_down(rt.InputButton.A) then
            local rail_x = select(1, self._rail:get_position())
            local rail_w = select(1, self._rail:get_size())


            if x >= rail_x and x <= rail_x + rail_w then
                self:set_value(self._lower + ((x - rail_x) / rail_w) * (self._upper - self._lower))
            end
        end
    end, out)

    return out
end)

--- @overload rt.Drawable.draw
function rt.Scale:draw()
    meta.assert_isa(self, rt.Scale)

    self._rail_start:draw()
    self._rail_start_outline:draw()
    self._rail_end:draw()
    self._rail_end_outline:draw()

    self._rail:draw()
    self._rail_outline_top:draw()
    self._rail_outline_bottom:draw()

    self._trough_start:draw()
    self._fill_start:draw()
    self._trough_start_outline:draw()
    self._trough_end:draw()
    self._fill_end:draw()
    self._trough_end_outline:draw()

    self._trough:draw()
    self._fill:draw()
    self._trough_outline_top:draw()
    self._trough_outline_bottom:draw()

    self._slider:draw()
    self._slider_outline:draw()

    if self._show_value then
        self._value_label:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Scale:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Scale)

    local slider_radius = rt.settings.scale.slider_radius
    local rail_radius = slider_radius * 0.5
    local rail_x = x + rail_radius
    local rail_y = y + rail_radius
    self._rail_start:resize(rail_x, rail_y, rail_radius)
    self._rail_start_outline:resize(rail_x, rail_y, rail_radius)
    self._rail_end:resize(x + width - rail_radius, rail_y, rail_radius)
    self._rail_end_outline:resize(x + width - rail_radius, rail_y, rail_radius)

    local rail_area = rt.AABB(x + rail_radius, y, width - 2 * rail_radius, 2 * rail_radius)
    self._rail:resize(rail_area)
    self._rail_outline_top:resize(rail_area.x, rail_area.y, rail_area.x + rail_area.width, rail_area.y)
    self._rail_outline_bottom:resize(rail_area.x, rail_area.y + rail_area.height, rail_area.x + rail_area.width, rail_area.y + rail_area.height)

    local trough_radius = rail_radius - rt.settings.scale.trough_offset
    self._trough_start:resize(rail_x, rail_y, trough_radius)
    self._trough_start_outline:resize(rail_x, rail_y, trough_radius)
    self._trough_end:resize(x + width - rail_radius, rail_y, trough_radius)
    self._trough_end_outline:resize(x + width - rail_radius, rail_y, trough_radius)

    self._fill_start:resize(rail_x, rail_y, trough_radius)
    self._fill_end:resize(x + width - rail_radius, rail_y, trough_radius)

    local trough_area = rt.AABB(rail_x, rail_y - trough_radius, width - 2 * rail_radius, 2 * trough_radius)
    self._trough:resize(trough_area)
    self._trough_outline_top:resize(trough_area.x, trough_area.y, trough_area.x + trough_area.width, trough_area.y)
    self._trough_outline_bottom:resize(trough_area.x, trough_area.y + trough_area.height, trough_area.x + trough_area.width, trough_area.y + trough_area.height)

    self._slider:set_radius(slider_radius)
    self._slider_outline:set_radius(slider_radius)

    self:_update_slider()
end

--- @brief [internal]
function rt.Scale:_update_slider()
    meta.assert_isa(self, rt.Scale)

    local x, y = self._rail:get_position()
    local w = select(1, self._rail:get_size())

    local slider_radius = rt.settings.scale.slider_radius
    local slider_x = x + ((self._value - self._lower) / (self._upper - self._lower)) * w
    local slider_y = y + 0.5 * slider_radius

    self._slider:resize(slider_x, slider_y, slider_radius)
    self._slider_outline:resize(slider_x, slider_y, slider_radius)

    local trough_x, trough_y = self._trough:get_position()
    local trough_w, trough_h = self._trough:get_size()
    self._fill:resize(rt.AABB(trough_x, trough_y, slider_x - trough_x, trough_h))

    self._fill_start:set_is_visible(slider_x > select(1, self._fill_start:get_center()))
    self._fill_end:set_is_visible(slider_x >= trough_x + trough_w)

    local label_w, label_h = self._value_label:measure()
    local label_area = rt.AABB(slider_x - 0.5 * label_w, slider_y - slider_radius - rt.settings.margin_unit - label_h, label_w, label_h)
    self._value_label:fit_into(label_area)
end

--- @brief
function rt.Scale:set_value(x)
    meta.assert_isa(self, rt.Scale)
    if self._value == x then return end

    -- round to nearest step increment
    if x >= self._upper then
        x = self._upper
    elseif x <= self._lower then
        x = self._lower
    else
        x = self._increment * math.round(x / self._increment)
    end
    self._value = x
    self._value_label:set_text(tostring(self._value))
    self:_update_slider()
    self:signal_emit("value_changed", self._value)
end

--- @brief
function rt.Scale:get_value()
    meta.assert_isa(self, rt.Scale)
    return self._value
end

--- @brief
function rt.Scale:set_color(color)
    meta.assert_isa(self, rt.Scale)
    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    meta.assert_rgba(color)
    self._fill_color = color
    self._fill_start:set_color(self._fill_color)
    self._fill:set_color(self._fill_color)
    self._fill_end:set_color(self._fill_color)
end

--- @brief
function rt.Scale:set_show_value(b)
    meta.assert_isa(self, rt.Scale)
    meta.assert_boolean(b)

    if b == true and not self._value_label:get_is_realized() then
        self._value_label:realize()
    end
    self._show_value = b
end

--- @brief
function rt.test.scale()
    error("TODO")
end