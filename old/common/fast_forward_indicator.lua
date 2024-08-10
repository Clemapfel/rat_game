rt.settings.fast_forward_indicator = {
    outline_thickness = 2,
    shader_path = "assets/shaders/fast_forward_indicator.glsl"
}

--- @class rt.FastForwardIndicator
rt.FastForwardIndicator = meta.new_type("FastForwardIndicator", rt.Widget, rt.Animation, function()
    return meta.new(rt.FastForwardIndicator, {
        _left_triangle = {},
        _left_triangle_outline = {},
        _right_triangle = {},
        _right_triangle_outline = {},
        _elapsed = 0,
        _shader = rt.Shader(rt.settings.fast_forward_indicator.shader_path)
    })
end)

--- @override
function rt.FastForwardIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self:size_allocate(0, 0, 1, 1)
end

--- @override
function rt.FastForwardIndicator:size_allocate(x, y, width, height)
    local y_radius = math.min(width, height) / 2;
    local x_radius = y_radius * 1.1
    local outline_width = rt.settings.fast_forward_indicator.outline_thickness

    x = math.floor(x)
    y = math.floor(y)

    local left_offset = 0.75 * x_radius
    self._left_triangle = rt.Circle(
        x + 0.5 * width - left_offset,
        y + 0.5 * height,
        x_radius,
        y_radius,
        3
    )

    self._left_triangle_outline = rt.Circle(
        x + 0.5 * width - left_offset,
        y + 0.5 * height,
        x_radius + outline_width,
        y_radius + outline_width,
        3
    )

    local right_offset = 0.5 * x_radius
    self._right_triangle = rt.Circle(
        x + 0.5 * width + right_offset,
        y + 0.5 * height,
        x_radius,
        y_radius,
        3
    )

    self._right_triangle_outline = rt.Circle(
        x + 0.5 * width + right_offset,
        y + 0.5 * height,
        x_radius + outline_width,
        y_radius + outline_width,
        3
    )

    for shape in range(self._left_triangle, self._right_triangle) do
        shape:set_color(rt.Palette.FOREGROUND)
    end

    for line in range(self._left_triangle_outline, self._right_triangle_outline) do
        line:set_color(rt.Palette.BACKGROUND)
        line:set_is_outline(true)
        line:set_line_width(outline_width)
    end
end

--- @override
function rt.FastForwardIndicator:draw()
    if self._is_realized == false then return end
    self._right_triangle_outline:draw()

    self._shader:bind()
    self._shader:send("elapsed", self._elapsed)
    self._right_triangle:draw()
    self._left_triangle:draw()
    self._shader:unbind()

    self._left_triangle_outline:draw()
end

--- @override
function rt.FastForwardIndicator:update(delta)
    self._elapsed = self._elapsed + delta
end