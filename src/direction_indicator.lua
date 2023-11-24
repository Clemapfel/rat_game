rt.settings.direction_indicator = {
    min_line_width = rt.settings.margin_unit,
    arrow_offset = 0 -- thickness factor
}

--- @class rt.DirectionIndicator
rt.DirectionIndicator = meta.new_type("DirectionIndicator", function(direction)
    if meta.is_nil(direction) then
        direction = rt.Direction.NONE
    end
    meta.assert_enum(direction, rt.Direction)
    local out = meta.new(rt.DirectionIndicator, {
        _direction = direction,
        _color = {},
        _ring = rt.Circle(0, 0, 1),
        _ring_outline_outer = rt.Circle(0, 0, 1),
        _ring_outline_inner = rt.Circle(0, 0, 1),
        _arrow = rt.Polygon(0, 0, 1, 1, 2, 2, 3, 3),
        _arrow_outline = rt.LineLoop(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)

    out:set_color(rt.Palette.FOREGROUND)

    out._ring:set_is_outline(true)
    out._ring_outline_inner:set_is_outline(true)
    out._ring_outline_outer:set_is_outline(true)

    out._ring:set_color(out._color)
    out._ring_outline_inner:set_color(rt.Palette.BASE_OUTLINE)
    out._ring_outline_outer:set_color(rt.Palette.BASE_OUTLINE)

    out._arrow:set_color(out._color)
    out._arrow_outline:set_color(rt.Palette.BASE_OUTLINE)
    return out
end)

--- @overload rt.Drawable.draw
function rt.DirectionIndicator:draw()
    if not self:get_is_visible() then return end
    if self._direction == rt.Direction.NONE then
        self._ring:draw()
        self._ring_outline_outer:draw()
        self._ring_outline_inner:draw()
    else
        self._arrow:draw()
        self._arrow_outline:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.DirectionIndicator:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.DirectionIndicator)

    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local radius = math.min(width, height) / 2
    local ring_thickness = 0.4 * radius
    local eps = 1
    if self._direction == rt.Direction.NONE then
        self._ring:resize(center_x, center_y, radius - 0.5 * ring_thickness)
        self._ring:set_line_width(ring_thickness)
        self._ring_outline_inner:resize(center_x, center_y, radius - ring_thickness)
        self._ring_outline_outer:resize(center_x, center_y, radius)
    else
        local thickness = math.max(radius / 2, rt.settings.direction_indicator.min_line_width)
        local vertices = {}

        if self._direction == rt.Direction.UP then
            vertices = {
                center_x, center_y - radius,
                center_x + radius, center_y,
                center_x + radius, center_y + thickness,
                center_x, center_y - radius + thickness,
                center_x - radius, center_y + thickness,
                center_x - radius, center_y
            }

            for i = 2, 12, 2 do
                vertices[i] = vertices[i] + rt.settings.direction_indicator.arrow_offset * thickness
            end
        elseif self._direction == rt.Direction.RIGHT then
            vertices = {
                center_x + radius, center_y,
                center_x, center_y + radius,
                center_x - thickness, center_y + radius,
                center_x + radius - thickness, center_y,
                center_x - thickness, center_y - radius,
                center_x, center_y - radius
            }

            for i = 1, 12, 2 do
                vertices[i] = vertices[i] - rt.settings.direction_indicator.arrow_offset * thickness
            end
        elseif self._direction == rt.Direction.DOWN then
            vertices = {
                center_x, center_y + radius - thickness,
                center_x + radius, center_y - thickness,
                center_x + radius, center_y,
                center_x, center_y + radius,
                center_x - radius, center_y,
                center_x - radius, center_y - thickness
            }

            for i = 2, 12, 2 do
                vertices[i] = vertices[i] - rt.settings.direction_indicator.arrow_offset * thickness
            end
        elseif self._direction == rt.Direction.LEFT then
            vertices = {
                center_x - radius + thickness, center_y,
                center_x + thickness, center_y + radius,
                center_x, center_y + radius,
                center_x - radius, center_y,
                center_x, center_y  - radius,
                center_x + thickness, center_y - radius
            }

            for i = 1, 12, 2 do
                vertices[i] = vertices[i] + rt.settings.direction_indicator.arrow_offset * thickness
            end
        end

        self._arrow:resize(splat(vertices))
        self._arrow_outline:resize(splat(vertices))
    end
end

--- @brief
function rt.DirectionIndicator:set_direction(direction)
    meta.assert_isa(self, rt.DirectionIndicator)
    meta.assert_enum(direction, rt.Direction)

    self._direction = direction
    self:reformat()
end

--- @brief
function rt.DirectionIndicator:get_direction()
    meta.assert_isa(self, rt.DirectionIndicator)
    return self._direction
end

--- @brief
function rt.DirectionIndicator:set_color(color)
    meta.assert_isa(self, rt.DirectionIndicator)
    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    meta.assert_rgba(color)
    self._color = color
    self._arrow:set_color(self._color)
    self._ring:set_color(self._color)
end

--- @brief
function rt.DirectionIndicator:get_color()
    meta.assert_isa(self, rt.DirectionIndicator)
    return self._color
end