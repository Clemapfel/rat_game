--- @class rt.Space
rt.Spacer = meta.new_type("Spacer", function(is_transparent)
    if meta.is_nil(is_transparent) then
        is_transparent = false
    end
    meta.assert_boolean(is_transparent)

    local out = meta.new(rt.Spacer, {
        _shape = rt.Rectangle(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)
    out._shape:set_color(rt.RGBA(0.5, 0.5, 0.5, 1))
    return out
end)

--- @overload rt.Drawable.draw
function rt.Spacer:draw()
    meta.assert_isa(self, rt.Spacer)
    self._shape:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Spacer:size_allocate(x, y, width, height)
    self._shape:set_position(x, y)
    self._shape:set_size(width, height)
end

--- @overload rt.Widget.measure
function rt.Spacer:measure()
    return self:get_minimum_size()
end

--- @brief set color
--- @param color rt.RGBA
function rt.Spacer:set_color(color)
    meta.assert_isa(self, rt.Spacer)
    rt.assert_rgba(color)
    self._shape:set_color(color)
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