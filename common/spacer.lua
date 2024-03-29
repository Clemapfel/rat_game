--- @class rt.Space
--- @param is_transparent Boolean (or nil)
rt.Spacer = meta.new_type("Spacer", rt.Widget, function(color)
    if meta.is_nil(color) then
        color = rt.Palette.BACKGROUND
    end

    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end

    local out = meta.new(rt.Spacer, {
        _shape = rt.Rectangle(0, 0, 1, 1),
        _outline_left = rt.Line(0, 0, 1, 1),
        _outline_top = rt.Line(0, 0, 1, 1),
        _outline_right = rt.Line(0, 0, 1, 1),
        _outline_bottom = rt.Line(0, 0, 1, 1),
        _color = color
    })

    out._shape:set_color(out._color)

    for outline in range(out._outline_top, out._outline_right, out._outline_bottom, out._outline_left) do
        outline:set_color(rt.RGBA(0, 0, 0, 1))
        outline:set_is_outline(true)
    end

    return out
end)

--- @overload rt.Drawable.draw
function rt.Spacer:draw()
    if not self:get_is_visible() then return end
    self._shape:draw()
    self._outline_top:draw()
    self._outline_bottom:draw()
    self._outline_left:draw()
    self._outline_right:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Spacer:size_allocate(x, y, width, height)

    local o = 1 -- outline width
    self._shape:resize(x , y, width, height)

    local top_left_x, top_left_y = x + o, y + o
    local top_right_x, top_right_y = x + width - o, y + o
    local bottom_right_x, bottom_right_y = x + width - o, y + height - o
    local bottom_left_x, bottom_left_y = x + o, y + height - o

    self._outline_top:resize(top_left_x, top_left_y, top_right_x, top_right_y)
    self._outline_right:resize(top_right_x, top_right_y, bottom_right_x, bottom_right_y)
    self._outline_bottom:resize(bottom_left_x, bottom_left_y, bottom_right_x, bottom_right_y)
    self._outline_left:resize(bottom_left_x, bottom_left_y, top_left_x, top_left_y)

    self._shape:set_opacity(self._opacity)
    self._outline_top:set_opacity(self._opacity)
    self._outline_right:set_opacity(self._opacity)
    self._outline_bottom:set_opacity(self._opacity)
    self._outline_left:set_opacity(self._opacity)
end

--- @override
function rt.Spacer:set_opacity(alpha)
    self._opacity = alpha
    self._shape:set_opacity(alpha)
    self._outline_left:set_opacity(alpha)
    self._outline_top:set_opacity(alpha)
    self._outline_right:set_opacity(alpha)
    self._outline_bottom:set_opacity(alpha)
end

--- @brief set color
--- @param color rt.RGBA
function rt.Spacer:set_color(color, outline_color)
    local rgba = color
    if meta.is_hsva(color) then
        rgba = rt.hsva_to_rgba(color)
    end

    self._shape:set_color(rgba)

    if not meta.is_nil(outline_color) then
        rgba = outline_color
        if meta.is_hsva(outline_color) then
            rgba = rt.hsva_to_rgba(outline_color)
        end

        for outline in range(self._outline_top, self._outline_right, self._outline_bottom, self._outline_left) do
            outline:set_color(outline_color)
        end
    end
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

--- @brief
function rt.Spacer:set_show_outline(top, right, bottom, left)
    if meta.is_nil(right) and meta.is_nil(bottom) and meta.is_nil(left) then
        local all = top
        self._outline_top:set_is_visible(all)
        self._outline_right:set_is_visible(all)
        self._outline_bottom:set_is_visible(all)
        self._outline_left:set_is_visible(all)
    else
        meta.assert_boolean(top, right, bottom, left)
        self._outline_top:set_is_visible(top)
        self._outline_right:set_is_visible(right)
        self._outline_bottom:set_is_visible(bottom)
        self._outline_left:set_is_visible(left)
    end
end
