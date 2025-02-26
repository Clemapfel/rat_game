--- @class PolygonType
rt.PolygonType = meta.enum("PolygonType", {
    LINE_STRIP = 0,
    DOTS = 1,
    POLYGON = 2
})

--- @class
rt.Polygon = meta.class("Polygon", rt.Shape)

--- @brief
function rt.Polygon:instantiate(...)
    local vertices = {...}
    meta.install(self, {
        _vertices = ternary(meta.is_table(vertices[1]), vertices[1], vertices),
        _type = rt.PolygonType.POLYGON,
        _centroid_x = 0,
        _centroid_y = 0
    })
    self:_update_centroid()
end

--- @brief
function rt.Polygon:draw()
    love.graphics.setColor(self._color_r, self._color_g, self._color_b, self._color_a)
    if self._outline_mode == "line" or self._type == rt.PolygonType.LINE_STRIP then
        love.graphics.setLineWidth(self._line_width)
        if self._line_join ~= nil then
            love.graphics.setLineJoin(self._line_join)
        end
    end

    if self._type == rt.PolygonType.POLYGON then
        love.graphics.polygon(
            self._outline_mode,
            table.unpack(self._vertices)
        )
    elseif self._type == rt.PolygonType.DOTS then
        love.graphics.points(table.unpack(self._vertices))
    elseif self._type == rt.PolygonType.LINE_STRIP then
        love.graphics.line(table.unpack(self._vertices))
    end
end

--- @brief
rt.Triangle = function(a_x, a_y, b_x, b_y, c_x, c_y)
    local out = rt.Polygon(a_x, a_y, b_x, b_y, c_x, c_y)
    return out
end

--- @brief
rt.Line = function(a_x, a_y, b_x, b_y)
    local out = rt.Polygon(a_x, a_y, b_x, b_y)
    out._type = rt.PolygonType.LINE_STRIP
    return out
end

--- @brief
rt.LineStrip = function(a_x, a_y, b_x, b_y, ...)
    local out = rt.Polygon(a_x, a_y, b_x, b_y, ...)
    out._type = rt.PolygonType.LINE_STRIP
    return out
end

--- @brief
rt.LineLoop = function(a_x, a_y, b_x, b_y, ...)
    local out = rt.Polygon(a_x, a_y, b_x, b_y, ...)
    table.insert(out._vertices, a_x)
    table.insert(out._vertices, a_y)
    out._type = rt.PolygonType.LINE_STRIP
    return out
end

--- @brief
rt.Dots = function(a_x, a_y, ...)
    local out = rt.Polygon(a_x, a_y, ...)
    out._type = rt.PolygonType.DOTS
    return out
end

--- @brief
rt.Dot = function(a_x, a_y)
    local out = rt.Polygon(a_x, a_y)
    out._type = rt.PolygonType.DOTS
    return out
end

--- @brief
function rt.Polygon:resize(a_x, a_y, b_x, b_y, ...)
    self._vertices = {a_x, a_y, b_x, b_y, ...}
end
