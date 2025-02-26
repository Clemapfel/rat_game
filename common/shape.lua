--- @class rt.LineJoin
rt.LineJoin = meta.enum("LineJoin", {
    MITER = "miter",
    NONE = "none",
    BEVEL = "bevel"
})


--- @class rt.Shape
rt.Shape = meta.abstract_class("Shape", rt.Drawable)

--- @brief
function rt.Shape:instantiate()
    meta.install(self, {
        _color_r = 1,
        _color_g = 1,
        _color_b = 1,
        _color_a = 1,
        _outline_mode = "fill",
        _use_anti_aliasing = true,
        _line_width = 1,
        _opacity = 1
    })
end

--- @brief set color of all vertices
--- @param rgba rt.RGBA
function rt.Shape:set_color(rgba)
    if meta.is_rgba(rgba) then
        self._color_r, self._color_g, self._color_b, self._color_a = rt.color_unpack(rgba)
    elseif meta.is_hsva(rgba) then
        self._color_r, self._color_g, self._color_b, self._color_a = rt.color_unpack(rt.hsva_to_rgba(rgba))
    else
        meta.assert_rgba(rgba)
    end
end

--- @brief get color of all vertices
function rt.Shape:get_color()
    return rt.RGBA(self._color_r, self._color_g, self._color_b, self._color_a)
end

--- @brief
function rt.Shape:set_is_outline(b)
    if b then self._outline_mode = "line" else self._outline_mode = "fill" end
end

--- @brief
function rt.Shape:get_is_outline()
    return self._outline_mode == "line"
end

--- @brief
function rt.Shape:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.Shape:get_opacity()
    return self._opacity
end

--- @brief
function rt.Shape:set_line_width(width)
    self._line_width = width
end

--- @brief
function rt.Shape:get_line_width()
    return self._line_width
end

--- @brief
function rt.Shape:set_line_join(line_join)
    self._line_join = line_join
end
