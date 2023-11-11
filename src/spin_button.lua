rt.settings.spin_button = {
    increase_label = "+",
    decrease_label = "–"
}

--- @class rt.SpinButton
rt.SpinButton = meta.new_type("SpinButton", function(lower, upper, value)
    value = ternary(meta.is_nil(value), mix(lower, upper, 0.5), value)
    local out = meta.new(rt.SpinButton, {
        _lower = math.min(lower, upper),
        _upper = math.max(upper, lower),
        _value = value,
        _value_label = rt.Label(tostring(value)),
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _increase_button_backdrop = rt.Rectangle(0, 0, 1, 1),
        _increase_button_outline = rt.Rectangle(0, 0, 1, 1),
        _increase_button_label = rt.Label(rt.settings.spin_button.increase_label, rt.settings.font.default_mono),
        _increase_button_disabled_overlay = rt.Rectangle(0, 0, 1, 1),
        _decrease_button_backdrop = rt.Rectangle(0, 0, 1, 1),
        _decrease_button_outline = rt.Rectangle(0, 0, 1, 1),
        _decrease_button_label = rt.Label(rt.settings.spin_button.decrease_label, rt.settings.font.default_mono),
        _decrease_button_disabled_overlay = rt.Rectangle(0, 0, 1, 1),
        _input = {}
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)

    out._backdrop:set_color(rt.Palette.BACKGROUND)
    out._backdrop_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

    out._backdrop:set_border_radius(rt.settings.margin_unit)
    out._backdrop_outline:set_border_radius(rt.settings.margin_unit)

    out._increase_button_backdrop:set_color(rt.Palette.BACKGROUND)
    out._increase_button_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._increase_button_disabled_overlay:set_color(rt.RGBA(0, 0, 0, 0.5))

    out._decrease_button_backdrop:set_color(rt.Palette.BACKGROUND)
    out._decrease_button_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._decrease_button_disabled_overlay:set_color(rt.RGBA(0, 0, 0, 0.5))

    for _, outline in pairs({out._backdrop_outline, out._increase_button_outline, out._decrease_button_outline}) do
        outline:set_is_outline(true)
    end

    out:signal_add("value_changed")
    --out:_update_value()

    return out
end)

--- @overload rt.Widget.realize
function rt.SpinButton:realize()
    meta.assert_isa(self, rt.SpinButton)

    self._value_label:realize()
    self._increase_button_label:realize()
    self._decrease_button_label:realize()

    rt.Widget.realize(self)
end

--- @overload rt.Drawable.draw
function rt.SpinButton:draw()
    meta.assert_isa(self, rt.SpinButton)

    self._backdrop:draw()
    self._backdrop_outline:draw()
    self._increase_button_backdrop:draw()
    self._decrease_button_backdrop:draw()
    self._increase_button_label:draw()
    self._decrease_button_label:draw()
    self._increase_button_outline:draw()
    self._decrease_button_outline:draw()
    self._value_label:draw()
end

--- @overload rt.Widget.measure
function rt.SpinButton:measure()
    local value_w, value_h = self._value_label:measure()
    local increase_w, increase_h = self._increase_button_label:measure()
    local decrease_w, decrease_h = self._decrease_button_label:measure()
    local min_w, min_h = self:get_minimum_size()

    return math.max(min_w, value_w + increase_w + increase_h + rt.settings.margin_unit * 2), math.max(min_h, math.max(value_h, increase_h, decrease_h))
end

--- @overload rt.Widget.size_allocate
function rt.SpinButton:size_allocate(x, y, width, height)
    local label_h = select(2, self._value_label:measure())
    local label_y_align = y + 0.5 * height - 0.5 * label_h

    local vexpand = self:get_expand_vertically()
    local hexpand = self:get_expand_horizontally()

    local button_width = math.max(select(1, self._increase_button_label:measure()), select(1, self._increase_button_label:measure()))
    local button_x = x + width - button_width

    if not vexpand then
        y = y - label_h * 0.5
    end

    self._backdrop:resize(rt.AABB(x, y, width, ternary(vexpand, height, label_h)))
    self._backdrop_outline:resize(rt.AABB(x, y, width, ternary(vexpand, height, label_h)))

    local increase_area = rt.AABB(button_x, y, button_width + 2 * rt.settings.margin_unit, ternary(vexpand, height, label_h))
    self._increase_button_backdrop:resize(increase_area)
    self._increase_button_outline:resize(increase_area)
    self._increase_button_disabled_overlay:resize(increase_area)
    self._increase_button_label:fit_into(rt.AABB(increase_area.x, label_y_align, increase_area.width, label_h))

    local decrease_area = rt.AABB(increase_area.x - increase_area.width, y, increase_area.width, ternary(vexpand, height, label_h))
    self._decrease_button_backdrop:resize(decrease_area)
    self._decrease_button_outline:resize(decrease_area)
    self._decrease_button_disabled_overlay:resize(decrease_area)
    self._decrease_button_label:fit_into(rt.AABB(decrease_area.x, label_y_align, decrease_area.width, label_h))

    self._value_label:fit_into(rt.AABB(x + rt.settings.margin_unit, label_y_align, width - increase_area.width - decrease_area.width, label_h))
end

function rt.SpinButton:_update_value()
    meta.assert_isa(self, rt.SpinButton)
    self._value_label:set_text(tostring(self._value))
    self._decrease_button_disabled_overlay:set_is_visible(self._value <= self._lower)
    self._increase_button_disabled_overlay:set_is_visible(self._value >= self._upper)
end

--- @brief
function rt.SpinButton:set_value(x)
    meta.assert_isa(self, rt.SpinButton)
    self._value = clamp(x, self._lower, self._upper)
    self:_update_value()
    self:signal_emit("value_changed", self._value)
end

--- @brief
function rt.SpinButton:get_value()
    meta.assert_isa(self, rt.SpinButton)
    return self._value
end