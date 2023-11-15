rt.settings.level_bar = {
    backdrop_darken_offset = 0.3
}

--- @class rt.LevelBar
rt.LevelBar = meta.new_type("LevelBar", function(lower, upper, value)
    meta.assert_number(lower, upper)
    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end
    meta.assert_number(value)

    local out = meta.new(rt.LevelBar, {
        _lower = lower,
        _upper = upper,
        _value = value,
        _shape = rt.Rectangle(0, 0, 1, 1),
        _shape_outline = rt.Line(0, 0, 1, 1),   -- right edge of bar, to avoid overlap with `_backdrop_outline`
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _color = rt.Palette.HIGHLIGHT
    }, rt.Drawable, rt.Widget)

    out._backdrop_outline:set_is_outline(true)
    out._shape_outline:set_is_outline(true)

    out._backdrop_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._shape_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

    out:set_color(out._color)
    out:_update_value()
    return out
end)

--- @brief [internal]
function rt.LevelBar:_update_value()
    meta.assert_isa(self, rt.LevelBar)
    local x, y = self._backdrop:get_position()
    local width, height = self._backdrop:get_size()
    local bounds = rt.AABB(x, y, ((self._value - self._lower) / (self._upper - self._lower)) * width, height)

    bounds = rt.AABB(math.round(bounds.x), math.round(bounds.y), math.round(bounds.width), math.round(bounds.height))
    self._shape:resize(bounds)
    self._shape_outline:resize(bounds.x + bounds.width, bounds.y, bounds.x + bounds.width, bounds.y + bounds.height)
end

--- @overload rt.Drawable.draw
function rt.LevelBar:draw()
    meta.assert_isa(self, rt.LevelBar)
    self._backdrop:draw()
    self._shape:draw()
    self._backdrop_outline:draw()
    self._shape_outline:draw()
end

--- @overload rt.Widget.size_allocate
function rt.LevelBar:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.LevelBar)

    local w, h = width, height
    if not self:get_expand_vertically() then
        h = rt.settings.font.default_size
    end

    local bounds = rt.AABB(math.round(x), math.round(y), w, h)
    self._backdrop:resize(bounds)
    self._backdrop_outline:resize(bounds)
    self:_update_value()
end

--- @brief
function rt.LevelBar:set_value(x)
    meta.assert_isa(self, rt.LevelBar)
    meta.assert_number(x)
    self._value = clamp(x, self._lower, self._upper)
    self:_update_value()
end

--- @brief
function rt.LevelBar:get_value()
    meta.assert_isa(self, rt.LevelBar)
    return self._value
end

--- @brief
function rt.LevelBar:set_color(color)
    meta.assert_isa(self, rt.LevelBar)
    meta.assert_rgba(color)
    self._color = color
    self._shape:set_color(self._color)
    self._backdrop:set_color(rt.color_darken(self._color, rt.settings.level_bar.backdrop_darken_offset))
end