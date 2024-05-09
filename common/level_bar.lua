rt.settings.level_bar = {
    backdrop_darken_offset = 0.3,
    corner_radius = rt.settings.margin_unit,
    outline_width = 3
}

--- @class rt.LevelBar
rt.LevelBar = meta.new_type("LevelBar", rt.Widget, function(lower, upper, value)
    meta.assert_number(lower, upper)
    value = which(value, mix(lower, upper, 0.5))

    local out = meta.new(rt.LevelBar, {
        _lower = lower,
        _upper = upper,
        _value = value,

        _shape = rt.Rectangle(0, 0, 1, 1),
        _shape_outline = rt.Line(0, 0, 1, 1),   -- right edge of bar, to avoid overlap with `_backdrop_outline`
        _corner_radius = rt.settings.level_bar.corner_radius,
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _color = rt.Palette.HIGHLIGHT,
        _backdrop_color = rt.color_darken(rt.Palette.HIGHLIGHT, rt.settings.level_bar.backdrop_darken_offset),
    })

    for outline in range(out._backdrop_outline, out._shape_outline) do
        outline:set_is_outline(true)
        outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    end

    out._backdrop_outline:set_line_width(3)
    out._shape_outline:set_line_width(1)

    out:set_color(out._color)
    return out
end)

--- @override
function rt.LevelBar:size_allocate(x, y, width, height)
    if not self._is_realized then return end
    self._backdrop:resize(x, y, width, height)
    self._backdrop_outline:resize(x, y, width, height)
    self:_update_value()
end

--- @override
function rt.LevelBar:draw()
    local stencil_value = meta.hash(self) % 255
    rt.graphics.stencil(stencil_value, self._backdrop)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    self._backdrop:draw()
    self._shape:draw()
    self._backdrop_outline:draw()
    self._shape_outline:draw()

    rt.graphics.stencil()
    rt.graphics.set_stencil_test()
end

--- @override
function rt.LevelBar:set_color(color, backdrop_color)
    if meta.is_hsva(color) then color = rt.hsva_to_rgba(color) end
    if meta.is_hsva(backdrop_color) then backdrop_color = rt.hsva_to_rgba(color) end

    self._color = color
    self._backdrop_color = ternary(meta.is_nil(backdrop_color), rt.color_darken(self._color, rt.settings.level_bar.backdrop_darken_offset), backdrop_color)

    self._shape:set_color(self._color)
    self._backdrop:set_color(self._backdrop_color)
end


--- @brief [internal]
function rt.LevelBar:_update_value()
    local x, y = self._backdrop:get_top_left()
    local width, height = self._backdrop:get_size()
    local bounds = rt.AABB(x, y, ((self._value - self._lower) / (self._upper - self._lower)) * width, height)
    bounds = rt.AABB(math.round(bounds.x), math.round(bounds.y), math.round(bounds.width), math.round(bounds.height))
    self._shape:resize(bounds)
    self._shape_outline:resize(bounds.x + bounds.width, bounds.y, bounds.x + bounds.width, bounds.y + bounds.height)
end

--- @brief
function rt.LevelBar:set_value(x)
    self._value = clamp(x, self._lower, self._upper)
    self:_update_value()
end

--- @brief
function rt.LevelBar:get_value()
    return self._value
end

--- @brief
function rt.LevelBar:set_corner_radius(radius)
    self._corner_radius = radius
    for shape in range(self._backdrop, self._backdrop_outline) do
        shape:set_corner_radius(radius)
    end
end

--- @brief
function rt.LevelBar:set_opacity(alpha)
    self._opacity = alpha
    self._shape:set_opacity(alpha)
    self._shape_outline:set_opacity(alpha)
    self._backdrop:set_opacity(alpha)
    self._backdrop_outline:set_opacity(alpha)
end