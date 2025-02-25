--- @class PolygonType
rt.PolygonType = meta.new_enum({
    LINE_STRIP = "LINE_STRIP",
    DOTS = "DOTS",
    POLYGON = "POLYGON"
})

--- @class
rt.Polygon = meta.new_type("Polygon", rt.Shape, function(...)
    local out = meta.new(rt.Polygon, {
        _vertices = {...},
        _type = rt.PolygonType.POLYGON,
        _centroid_x = 0,
        _centroid_y = 0
    })
    out:_update_centroid()
    return out
end)

--- @brief
function rt.Polygon:draw()
    self:_bind_properties()
    if self._type == rt.PolygonType.POLYGON then
        love.graphics.polygon(
            self._outline_mode,
            splat(self._vertices)
        )
    elseif self._type == rt.PolygonType.DOTS then
        love.graphics.points(splat(self._vertices))
    elseif self._type == rt.PolygonType.LINE_STRIP then
        love.graphics.line(splat(self._vertices))
    end
    self._unbind_properties()
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
function rt.Polygon:_update_centroid()
    local x_sum, y_sum = 0, 0
    for i = 1, #self._vertices - 1, 2 do
        x_sum = x_sum + self._vertices[i+0]
        y_sum = y_sum + self._vertices[i+1]
    end
    self._centroid_x = x_sum / #self._vertices
    self._centroid_y = y_sum / #self._vertices
end

--- @brief
function rt.Polygon:get_centroid()
    return self._centroid_x, self._centroid_y
end

--- @brief
function rt.Polygon:set_centroid(x, y)

    --[[
    local offsets = {}
    for i = 1, #self._vertices, 2 do
        offsets[i+0] = self._vertices[i+0] - self._centroid_x
        offsets[i+1] = self._vertices[i+1] - self._centroid_y
    end

    self._vertices = {}
    for i = 1, #offsets, 2 do
        self._vertices[i+0] = x + offsets[i+0]
        self._vertices[i+1] = y + offsets[i+1]
    end

    self._centroid_x = x
    self._centroid_y = y
    ]]--

    local offset_x = x - self._centroid_x
    local offset_y = y - self._centroid_y
    for i = 1, #self._vertices - 1, 2 do
        self._vertices[i+0] = self._vertices[i+0] + offset_x
        self._vertices[i+1] = self._vertices[i+1] + offset_y
    end
    self._centroid_x = x
    self._centroid_y = y
end

--- @brief
function rt.Polygon:resize(a_x, a_y, b_x, b_y, ...)
    self._vertices = {a_x, a_y, b_x, b_y, ...}
    self:_update_centroid()
end

--- @brief
function rt.Polygon:get_bounds()
    local min_x, min_y = POSITIVE_INFINITY, POSITIVE_INFINITY
    local max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY
    for i = 1, #self._vertices, 2 do
        local x, y = self._vertices[i], self._vertices[i+1]
        min_x = math.min(min_x, x)
        min_y = math.min(min_y, y)
        max_x = math.max(max_x, x)
        max_y = math.max(max_y, y)
    end
    return rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y)
end
