rt.settings.spacer = {
    default_opacity = 0.8
}

--- @class rt.Spacer
rt.Spacer = meta.new_type("Spacer", rt.Widget, function()
    return meta.new(rt.Spacer, {
        _shape = rt.Rectangle(0, 0, 1, 1),
        _color = rt.Palette.BACKGROUND
    })
end)

--- @override
function rt.Spacer:realize()
    if self:already_realized() then return end

    self._shape:set_color(self._color)
end

--- @override
function rt.Spacer:size_allocate(x, y, width, height)
    self._shape:resize(x, y, width, height)
end

--- @override
function rt.Spacer:draw()
    self._shape:draw()
end

--- @override
function rt.Spacer:set_opacity(alpha)
    meta.assert_number(alpha)
    self._shape:set_opacity(alpha)
end

--- @brief
function rt.Spacer:set_color(color)
    self._color = color
    self._shape:set_color(color)
end

--- @brief
function rt.Spacer:get_color()
    return self._color
end

--- @brief
function rt.Spacer:set_corner_radius(r)
    self._shape:set_corner_radius(r)
end
