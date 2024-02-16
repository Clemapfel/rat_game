--- @class rt.LineJoin
rt.LineJoin = meta.new_enum({
    MITER = "miter",
    NONE = "none",
    BEVEL = "bevel"
})

--- @class rt.Shape
rt.Shape = meta.new_abstract_type("Shape", rt.Drawable, {
    _color = rt.RGBA(1, 1, 1, 1),
    _is_outline = false,
    _use_anti_aliasing = true,
    _line_width = 1,
})

--- @brief [internal]
function rt.Shape:_bind_properties(callback, data)
    love.graphics.push()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    love.graphics.setLineWidth(self._line_width)
    love.graphics.setPointSize(self._line_width)
end

--- @brief [internal]
function rt.Shape:_unbind_properties(callback, data)
    love.graphics.pop()
end

--- @brief set color of all vertices
--- @param rgba rt.RGBA
function rt.Shape:set_color(rgba)
    if meta.is_rgba(rgba) then
        self._color = rgba
    elseif meta.is_hsva(rgba) then
        self._color = rt.hsva_to_rgba(rgba)
    else
        meta.assert_rgba(rgba)
    end
end

--- @brief get color of all vertices
function rt.Shape:get_color()
    return self._color
end

--- @brief
function rt.Shape:set_is_outline(b)
    self._is_outline = b
end

--- @brief
function rt.Shape:get_is_outline()
    return self._is_outline
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

for _, name in pairs(love.filesystem.getDirectoryItems("common/shapes")) do
    name = string.sub(name, 1, #name - 4) -- remove `.lua`
    require("common.shapes." .. name)
end
