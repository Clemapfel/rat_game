--- @class rt.Space
rt.Spacer = meta.new_type("Space", function(is_transparent)
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

--- @overlay rt.Widget.size_allocate
function rt.Spacer:size_allocate(x, y, width, height)
    self._shape:set_position(x, y)
    self._shape:set_size(width, height)
end

--- @brief set color
--- @param color rt.RGBA
function rt.Spacer:set_color(color)
    meta.assert_isa(self, rt.Spacer)
    self._shape:set_color(color)
end