rt.settings.switch = {
    slider_radius = rt.settings.font.default_size,
    outline_width = 3
}

--- @class rt.Switch
--- @signal switched (self, current_state) -> nil
rt.Switch = meta.new_type("Switch", function()
    local out = meta.new(rt.Switch, {
        _input = {},
        _slider = rt.Circle(0, 0, 1),
        _slider_outline = rt.Circle(0, 0, 1),
        _start = rt.Circle(0, 0, 1),
        _start_outline = rt.Circle(0, 0, 1),
        _center = rt.Rectangle(0, 0, 1, 1),
        _center_outline_top = rt.Line(0, 0, 1, 1),
        _center_outline_bottom = rt.Line(0, 0, 1, 1),
        _end = rt.Circle(0, 0, 1),
        _end_outline = rt.Circle(0, 0, 1),
        _is_on = false,
        _on_color = rt.Palette.HIGHLIGHT,
        _off_color = rt.Palette.BACKGROUND
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)

    out._input = rt.InputController(out)

    out._slider:set_color(rt.Palette.FOREGROUND)
    out._slider_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)

    for outline in pairs(
        out._start_outline,
        out._center_outline_top,
        out._center_outline_bottom,
        out._end_outline
    ) do
        outline:set_is_outline(true)
        outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    end

    out._slider_outline:set_is_outline(true)
    out._slider_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)

    out:_update_slider()
    out:signal_add("toggled")

    out._input:signal_connect("pressed", function(_, button, self)
        if button == rt.InputButton.A then
            self:set_is_on(not self:get_is_on())
        end
    end, out)

    return out
end)

--- @brief
function rt.Switch:_update_slider()

    if self._is_on == false then
        local pos_x, pos_y = self._start:get_center()
        local radius = self._start:get_radius()
        self._slider:set_center(pos_x, pos_y)
        self._slider_outline:set_center(pos_x, pos_y)

        self._start:set_color(self._off_color)
        self._center:set_color(self._off_color)
        self._end:set_color(self._off_color)

    else
        local pos_x, pos_y = self._end:get_center()
        local radius = self._end:get_radius()
        self._slider:set_center(pos_x, pos_y)
        self._slider_outline:set_center(pos_x, pos_y)


        self._start:set_color(self._on_color)
        self._center:set_color(self._on_color)
        self._end:set_color(self._on_color)
    end
end

--- @overload rt.Drawable.draw
function rt.Switch:draw()

    if not self:get_is_visible() then return end


    self._start:draw()
    self._end:draw()
    self._start_outline:draw()
    self._end_outline:draw()
    self._center:draw()
    self._center_outline_top:draw()
    self._center_outline_bottom:draw()
    self._slider:draw()
    self._slider_outline:draw()
end

--- @overload rt.Widget.size_allocate()
function rt.Switch:size_allocate(x, y, width, height)


    local slider_radius = rt.settings.switch.slider_radius
    self._slider:set_radius(slider_radius)
    self._slider_outline:set_radius(slider_radius)

    local length = 4 * slider_radius
    x = x + 0.5 * width - 0.5 * length
    y = y + 0.5 * height - 1 * slider_radius

    for shape in range(self._start, self._start_outline) do
        shape:resize(x + slider_radius, y + slider_radius, slider_radius)
    end

    for shape in range(self._end, self._end_outline) do
        shape:resize(x + length - slider_radius, y + slider_radius, slider_radius)
    end

    local start_x, start_y = self._start:get_center()
    local end_x, end_y = self._end:get_center()
    self._center:resize(rt.AABB(start_x, start_y - slider_radius, length - 2 * slider_radius, 2 * slider_radius))
    self._center_outline_top:resize(start_x, start_y - slider_radius, end_x, end_y - slider_radius)
    self._center_outline_bottom:resize(start_x, start_y + slider_radius, end_x, end_y + slider_radius)

    self:_update_slider()
end

--- @brief
function rt.Switch:set_is_on(b)

    local before = self._is_on
    self._is_on = b

    if before ~= b then
        self:_update_slider()
        self:signal_emit("toggled", self._is_on)
    end
end

--- @brief
function rt.Switch:get_is_on()

    return self._is_on
end