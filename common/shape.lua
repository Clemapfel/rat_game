--- @class rt.LineJoin
rt.LineJoin = meta.new_enum({
    MITER = "miter",
    NONE = "none",
    BEVEL = "bevel"
})

--- @class rt.Shape
rt.Shape = meta.new_abstract_type("Shape", rt.Drawable, {
    _color_r = 1,
    _color_g = 1,
    _color_b = 1,
    _color_a = 1,
    _is_outline = false,
    _use_anti_aliasing = true,
    _line_width = 1,
    _opacity = 1
})

--- @brief [internal]
function rt.Shape:_bind_properties(callback, data)

    --love.graphics.push()
    love.graphics.setColor(self._color_r, self._color_g, self._color_b, self._color_a * self._opacity)
    love.graphics.setLineWidth(self._line_width)

    if self._line_join ~= nil then
        love.graphics.setLineJoin(self._line_join)
    end
end

--- @brief [internal]
function rt.Shape:_unbind_properties(callback, data)
    --love.graphics.pop()
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
    self._is_outline = b
end

--- @brief
function rt.Shape:get_is_outline()
    return self._is_outline
end

--- @brief
function rt.Shape:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.Shape:get_opacity()
    return self._opacity
end

--- @brief virutal
function rt.Shape:get_centroid()
    rt.error("In rt.Shape:get_centroid: abstract method called")
end

--- @brief virutal
function rt.Shape:set_centroid(x, y)
    rt.error("In rt.Shape:set_centroid: abstract method called")
end

--- @brief virutal
function rt.Shape:get_bounds()
    rt.error("In rt.Shape:get_bounds: abstract method called")
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
