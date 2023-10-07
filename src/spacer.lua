--- @class rt.Space
rt.Spacer = meta.new_type("Spacer", function(is_transparent)
    if meta.is_nil(is_transparent) then
        is_transparent = false
    end
    meta.assert_boolean(is_transparent)

    local out = meta.new(rt.Spacer, {
        _shape = rt.Rectangle(0, 0, 1, 1),
        _outline = rt.Rectangle(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)
    out._shape:set_color(rt.Palette.BACKGROUND_COLOR_OUTLINE)
    out._shape_outline:set_color(rt.Palette.darken(rt.Palette.BACKGROUND_COLOR_OUTLINE), 0.1)
    out._shape_outline:set_is_outline(true)
    return out
end)

--- @overload rt.Drawable.draw
function rt.Spacer:draw()
    meta.assert_isa(self, rt.Spacer)
    self._shape:draw()
    self._outline:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Spacer:size_allocate(x, y, width, height)
    self._shape:set_position(x, y)
    self._shape:set_size(width, height)
end

--- @overload rt.Widget.measure
function rt.Spacer:measure()
    local w, h = self:get_minimum_size()
    w = w + self:get_margin_left() + self:get_margin_right()
    h = h + self:get_margin_top() + self:get_margin_bottom()
    return w, h
end

--- @brief set color
--- @param color rt.RGBA
function rt.Spacer:set_color(color)
    meta.assert_isa(self, rt.Spacer)

    local rgba = color
    if rt.is_hsva(color) then
        rgba = rt.hsav_to_rgba(color)
    end

    rt.assert_rgba(rgba)
    self._shape:set_color(rgba)
    self._shape_outline:set_color(rt.Palette.darken(rgba, 0.1))
end

--- @brief get color
--- @return rt.RGBA
function rt.Spacer:get_color()
    meta.assert_isa(self, rt.Spacer)
    return self._shape:get_color()
end

--- @brief test Spacer
function rt.test.spacer()
    -- TODO
end
rt.test.spacer()