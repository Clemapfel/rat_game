--- @class rt.Space
--- @param is_transparent Boolean (or nil)
rt.Spacer = meta.new_type("Spacer", function(color)
    if meta.is_nil(color) then
        color = rt.Palette.BACKGROUND
    end

    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end

    local out = meta.new(rt.Spacer, {
        _shape = rt.Rectangle(0, 0, 1, 1),
        _outline = rt.Rectangle(0, 0, 1, 1),
        _color = color
    }, rt.Drawable, rt.Widget)

    out._shape:set_color(out._color)
    out._outline:set_color(rt.RGBA(0, 0, 0, 1))
    out._outline:set_is_outline(true)

    for _, shape in pairs({out._shape, out._outline}) do
        --shape:set_corner_radius(rt.settings.margin_unit)
    end
    return out
end)

--- @overload rt.Drawable.draw
function rt.Spacer:draw()
    if not self:get_is_visible() then return end

    self._shape:draw()
    self._outline:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Spacer:size_allocate(x, y, width, height)

    self._shape:resize(x, y, width, height)
    self._outline:resize(x, y, width, height)
end

--- @brief set color
--- @param color rt.RGBA
function rt.Spacer:set_color(color, outline_color)

    local rgba = color
    if meta.is_hsva(color) then
        rgba = rt.hsav_to_rgba(color)
    end

    self._shape:set_color(rgba)

    local rgba = outline_color
    if meta.is_hsva(outline_color) then
        rgba = rt.hsav_to_rgba(outline_color)
    end

    self._outline:set_color(rgba)
end

--- @brief get color
--- @return rt.RGBA
function rt.Spacer:get_color()
    return self._shape:get_color()
end

--- @brief
function rt.Spacer:set_corner_radius(r)
    self._shape:set_corner_radius(r)
end

--- @brief test Spacer
function rt.test.spacer()
    error("TODO")
end
