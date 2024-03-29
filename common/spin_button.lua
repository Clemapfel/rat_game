rt.settings.spin_button = {
    increase_label = "+",
    decrease_label = "–",
    frame_offset = 5 -- distance between backdrop and value_label_area
}

--- @class rt.SpinButton
rt.SpinButton = meta.new_type("SpinButton", rt.Widget, rt.SignalEmitter, function(lower, upper, increment, value)
    value = ternary(meta.is_nil(value), mix(lower, upper, 0.5), value)
    local out = meta.new(rt.SpinButton, {
        _lower = math.min(lower, upper),
        _upper = math.max(upper, lower),
        _increment = increment,
        _value = value,
        _value_label = rt.Label(tostring(value)),
        _value_label_area = rt.Rectangle(0, 0, 1, 1),
        _value_label_area_outline = rt.Rectangle(0, 0, 1, 1),
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
    })

    out._backdrop:set_color(rt.Palette.BASE)
    out._backdrop_outline:set_color(rt.Palette.BASE_OUTLINE)

    out._backdrop:set_corner_radius(rt.settings.margin_unit)
    out._backdrop_outline:set_corner_radius(rt.settings.margin_unit)
    out._value_label_area_outline:set_corner_radius(rt.settings.margin_unit)
    out._value_label_area:set_corner_radius(rt.settings.margin_unit)

    out._increase_button_backdrop:set_color(rt.Palette.BASE)
    out._increase_button_outline:set_color(rt.Palette.BASE_OUTLINE)
    out._increase_button_disabled_overlay:set_color(rt.RGBA(0, 0, 0, 0.5))
    out._increase_button_disabled_overlay:set_is_visible(value >= out._upper)

    out._value_label_area:set_color(rt.Palette.BACKGROUND)
    out._value_label_area_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._value_label_area_outline:set_is_outline(true)

    out._decrease_button_backdrop:set_color(rt.Palette.BASE)
    out._decrease_button_outline:set_color(rt.Palette.BASE_OUTLINE)
    out._decrease_button_disabled_overlay:set_color(rt.RGBA(0, 0, 0, 0.5))
    out._decrease_button_disabled_overlay:set_is_visible(value <= out._lower)

    for outline in range(out._backdrop_outline, out._increase_button_outline, out._decrease_button_outline) do
        outline:set_is_outline(true)
    end

    out:signal_add("value_changed")

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(controller, button, self)

        local increment = function()
            self:set_value(self:get_value() + self._increment)
            self._increase_button_disabled_overlay:set_is_visible(true)
        end

        local decrement = function()
            self:set_value(self:get_value() - self._increment)
            self._decrease_button_disabled_overlay:set_is_visible(true)
        end

        if button == rt.InputButton.UP then
            increment()
        elseif button == rt.InputButton.DOWN then
            decrement()
        end

        local cursor_x, cursor_y = controller:get_cursor_position()
        if rt.aabb_contains(self._increase_button_backdrop:get_bounds(), cursor_x, cursor_y) then
            increment()
        elseif rt.aabb_contains(self._decrease_button_backdrop:get_bounds(), cursor_x, cursor_y) then
            decrement()
        end
    end, out)

    out._input:signal_connect("released", function(_, button, self)
        self._increase_button_disabled_overlay:set_is_visible(self._value >= self._upper)
        self._decrease_button_disabled_overlay:set_is_visible(self._value <= self._lower)
    end, out)

    return out
end)

--- @overload rt.Widget.realize
function rt.SpinButton:realize()


    self._value_label:realize()
    self._increase_button_label:realize()
    self._decrease_button_label:realize()

    rt.Widget.realize(self)
end

--- @overload rt.Drawable.draw
function rt.SpinButton:draw()

    if not self:get_is_visible() then return end


    self._backdrop:draw()
    self._backdrop_outline:draw()
    self._value_label_area:draw()
    self._value_label_area_outline:draw()
    self._increase_button_backdrop:draw()
    self._decrease_button_backdrop:draw()
    self._increase_button_label:draw()
    self._decrease_button_label:draw()
    self._increase_button_outline:draw()
    self._decrease_button_outline:draw()
    self._increase_button_disabled_overlay:draw()
    self._decrease_button_disabled_overlay:draw()
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
    local eps = rt.settings.spin_button.frame_offset
    local label_h = select(2, self._value_label:measure()) + 2 * eps
    local label_y_align = y + 0.5 * height - 0.5 * label_h

    -- manually align + and - to align, this may need to be changed if rt.settings.spin_button.*_label changes
    local increase_label_y_align = label_y_align - 0.025 * self._increase_button_label:get_font():get_size()
    local decrease_label_y_align = label_y_align - 0.05 * self._increase_button_label:get_font():get_size()

    local vexpand = self:get_expand_vertically()
    local hexpand = self:get_expand_horizontally()

    local button_width = math.max(select(1, self._increase_button_label:measure()), select(1, self._increase_button_label:measure())) + 2 * rt.settings.margin_unit

    if not vexpand then
        y = y - label_h * 0.5
    end

    local backdrop_area = rt.AABB(x, y, width, ternary(vexpand, height, label_h))
    self._backdrop:resize(backdrop_area)
    self._backdrop_outline:resize(backdrop_area)

    self._value_label_area:resize(rt.AABB(x + eps, y + eps, backdrop_area.width - 2 * eps, backdrop_area.height - 2 * eps))
    self._value_label_area_outline:resize(rt.AABB(x + eps, y + eps, backdrop_area.width - 2 * eps, backdrop_area.height - 2 * eps))

    local button_x = backdrop_area.x + backdrop_area.width - button_width

    local increase_area = rt.AABB(button_x, y, button_width, ternary(vexpand, height, label_h))
    self._increase_button_backdrop:resize(increase_area)
    self._increase_button_outline:resize(increase_area)
    self._increase_button_disabled_overlay:resize(increase_area)
    self._increase_button_label:fit_into(rt.AABB(increase_area.x, increase_label_y_align, increase_area.width, label_h))

    local decrease_area = rt.AABB(increase_area.x - increase_area.width, y, increase_area.width, ternary(vexpand, height, label_h))
    self._decrease_button_backdrop:resize(decrease_area)
    self._decrease_button_outline:resize(decrease_area)
    self._decrease_button_disabled_overlay:resize(decrease_area)
    self._decrease_button_label:fit_into(rt.AABB(decrease_area.x, decrease_label_y_align, decrease_area.width, label_h))

    self._value_label:fit_into(rt.AABB(x + rt.settings.margin_unit, label_y_align, width - increase_area.width - decrease_area.width, label_h))
end

function rt.SpinButton:_update_value()

    self._value_label:set_text(tostring(self._value))
    self._decrease_button_disabled_overlay:set_is_visible(self._value <= self._lower)
    self._increase_button_disabled_overlay:set_is_visible(self._value >= self._upper)
end

--- @brief
function rt.SpinButton:set_value(x)

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
    self:_update_value()
    self:signal_emit("value_changed", self._value)
end

--- @brief
function rt.SpinButton:get_value()

    return self._value
end

--- @brief
function rt.test.spin_button()
    error("TODO")
end