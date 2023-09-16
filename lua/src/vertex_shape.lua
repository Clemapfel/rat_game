--- @class Image

--- @class
rt.SpriteBatchUsage = meta.new_enum({
    DYNAMIC = "dynamic",
    STATIC = "static",
    STREAM = "stream"
})

--- @class
rt.MeshDrawMode = meta.new_enum({
    TRIANGLE_FAN = "fan",
    TRIANGLE_STRIP = "strip",
    TRIANGLE_LIST = "triangles",
    POINTS = "points"
})

--- @brief
function rt.Vertex(top_left_x, top_left_y, texture_coordinate_x, texture_coordinate_y, color)
    meta.assert_number(top_left_x, top_left_y, texture_coordinate_x, texture_coordinate_y)

    if meta.is_nil(color) then
        color = rt.RGBA(1, 1, 1, 1)
    end
    rt.assert_rgba(color)

    return {
        top_left_x, top_left_y,
        texture_coordinate_x, texture_coordinate_y,
        color.r, color.g, color.b, color.a
    }
end

--- @class VertexShape
--- @param vararg Vector2
rt.VertexShape = meta.new_type("VertexShape", function(...)
    local positions = {...}
    local vertices = {}
    for _, pos in ipairs(positions) do
        rt.assert_vector2(pos)
        table.insert(vertices, rt.Vertex(pos.x, pos.y, 0, 0))
    end
    local out = meta.new(rt.VertexShape, {
        _mesh = love.graphics.newMesh(vertices,
            rt.MeshDrawMode.TRIANGLE_STRIP,
            rt.SpriteBatchUsage.DYNAMIC
        )
    }, rt.Drawable)
    out:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
    return out
end)

rt.VertexAttribute = meta.new_enum({
    POSITION = "VertexPosition",
    TEXTURE_COORDINATES = "VertexTexCoord",
    COLOR = "VertexColor"
})

--- @brief
function rt.VertexShape:get_n_vertices()
    meta.assert_isa(self, rt.VertexShape)
    return self._mesh:getVertexCount()
end

--- @brief
function rt.VertexShape:set_vertex_color(i, rgba)
    meta.assert_isa(self, rt.VertexShape)
    rt.assert_rgba(rgba)
    self._mesh:setVertexAttribute(i, 3, rgba.r, rgba.g, rgba.b, rgba.a)
end

--- @brief
function rt.VertexShape:get_vertex_color(i)
    meta.assert_isa(self, rt.VertexShape)

    local r, g, b, a
    r, g, b, a = self._mesh:getVertexAttribute(i, 3)
    return rt.RGBA(r, g, b, a)
end

--- @brief
function rt.VertexShape:set_vertex_position(i, x, y)
    meta.assert_isa(self, rt.VertexShape)
    meta.assert_number(x, y)

    self._mesh:setVertexAttribute(i, 1, x, y)
end

--- @brief
--- @return Vector2
function rt.VertexShape:get_vertex_position(i)
    meta.assert_isa(self, rt.VertexShape)

    local x, y
    x, y = self._mesh:getVertexAttribute(i, 1)
    return rt.Vector2(x, y)
end

--- @brief
function rt.VertexShape:set_vertex_texture_coordinate(i, u, v)
    meta.assert_isa(self, rt.VertexShape)
    meta.assert_number(u, v)

    self._mesh:setVertexAttribute(i, 2, u, v)
end

--- @brief
--- @return Vector2
function rt.VertexShape:get_vertex_texture_coordinate(i)
    local u, v
    u, v = self._mesh:getVertexAttribute(i, 2)
    return rt.Vector2(u, v)
end

--- @brief
function rt.VertexShape:set_color(rgba)
    meta.assert_isa(self, rt.VertexShape)
    rt.assert_rgba(rgba)
    for i = 1, self:get_n_vertices() do
        self:set_vertex_color(i, rgba)
    end
end

--- @brief
function rt.VertexShape:set_texture_rectangle(rectangle)
    meta.assert_isa(self, rt.VertexShape)
    meta.assert_isa(rectangle, rt.AxisAlignedRectangle)

    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY
    for i = 1, self:get_n_vertices() do
        local pos = self:get_vertex_position(i)
        min_x = math.min(pos.x, min_x)
        max_x = math.max(pos.x, max_x)
        min_y = math.min(pos.y, min_y)
        max_y = math.max(pos.y, max_y)
    end

    local width = (max_x - min_x)
    local height = (max_y - min_y)
    for i = 1, self:get_n_vertices() do
        local pos = self:get_vertex_position(i)
        self:set_vertex_texture_coordinate(i,
            (pos.x - min_x) / (width / rectangle.width) + rectangle.x,
            (pos.y - min_y) / (height / rectangle.height) + rectangle.y
        )
    end
end

--- @brief
function rt.VertexShape:draw()
    love.graphics.draw(self._mesh)
end


