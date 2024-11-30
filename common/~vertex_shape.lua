--- @class rt.GraphicsBufferUsage
rt.GraphicsBufferUsage = meta.new_enum("GraphicsBufferUsage", {
    DYNAMIC = "dynamic",
    STATIC = "static",
    STREAM = "stream"
})

--- @class rt.MeshDrawMode
rt.MeshDrawMode = meta.new_enum("MeshDrawMode", {
    TRIANGLE_FAN = "fan",
    TRIANGLE_STRIP = "strip",
    TRIANGLES = "triangles",
    POINTS = "points"
})

--- @class rt.VertexAttribute
rt.VertexAttribute = meta.new_enum("VertexAttribute", {
    POSITION = "VertexPosition",
    TEXTURE_COORDINATES = "VertexTexCoord",
    COLOR = "VertexColor"
})

if love.getVersion() >= 12 then
    rt.VertexFormat = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
        {name = "VertexColor", format = "floatvec4"},
    }
else
    rt.VertexFormat = {
        {"VertexPosition", "float", 2},
        {"VertexTexCoord","float", 2},
        {"VertexColor", "float", 4},
    }
end

--- @class rt.Vertex
--- @param x Number in px
--- @param y Number in px
--- @param z Number in px
--- @param texture_coordinate_x Number in [0, 1]
--- @param texture_coordinate_y Number in [0, 1]
--- @param color rt.RGBA
function rt.Vertex(x, y, texture_coordinate_x, texture_coordinate_y, color)
    if color == nil then
        color = rt.RGBA(1, 1, 1, 1)
    end
    return {
        x, y,
        texture_coordinate_x, texture_coordinate_y,
        color.r, color.g, color.b, color.a
    }
end

--- @class rt.VertexShape
--- @param vararg rt.Vector2
rt.VertexShape = meta.new_type("VertexShape", rt.Drawable, function(points)
    local vertices = {}
    for _, pos in pairs(points) do
        table.insert(vertices, rt.Vertex(pos[1], pos[2], 0, 0))
    end

    local out = meta.new(rt.VertexShape, {
        _native = love.graphics.newMesh(
            rt.VertexFormat,
            vertices,
            rt.MeshDrawMode.TRIANGLE_FAN,
            rt.GraphicsBufferUsage.DYNAMIC
        ),
        _opacity = 1
    })
    out:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
    return out
end)

--- @brief get number of vertices
--- @return Number
function rt.VertexShape:get_n_vertices()
    return self._native:getVertexCount()
end

--- @brief
function rt.VertexShape:set_vertex_order(map)
    self._native:setVertexMap(map)
end

--- @brief set color of one vertex
--- @param i Number 1-based
--- @param rgba rt.RGBA
function rt.VertexShape:set_vertex_color(i, r_or_rgba, g, b, a)
    if meta.is_number(r_or_rgba) then
        local r = r_or_rgba
        self._native:setVertexAttribute(i, 3, r, g, b, a * self._opacity)
    else
        local rgba = r_or_rgba
        if meta.is_hsva(rgba) then rgba = rt.hsva_to_rgba(rgba) end
        self._native:setVertexAttribute(i, 3, rgba.r, rgba.g, rgba.b, rgba.a * self._opacity)
    end
end

--- @brief get color of one vertex
--- @param i Number 1-based
--- @return rt.RGBA
function rt.VertexShape:get_vertex_color(i)
    local r, g, b, a = self._native:getVertexAttribute(i, 3)
    return rt.RGBA(r, g, b, a)
end

--- @brief set vertex position
--- @param i Number 1-based
--- @param x Number in px
--- @param y Number in px
function rt.VertexShape:set_vertex_position(i, x, y)
    self._native:setVertexAttribute(i, 1, x, y)
end

--- @brief get position of vertex
--- @param i Number 1-based
--- @return (Number, Number)
function rt.VertexShape:get_vertex_position(i)
    return self._native:getVertexAttribute(i, 1)
end

--- @brief get vertex texture coordinate
--- @param i Number 1-based
--- @param u Number in [0, 1]
--- @param v Number in [0, 1]
function rt.VertexShape:set_vertex_texture_coordinate(i, u, v)
    self._native:setVertexAttribute(i, 2, u, v)
end

--- @brief get texture coordinate
--- @return (Number, Number)
function rt.VertexShape:get_vertex_texture_coordinate(i)
    return self._native:getVertexAttribute(i, 2)
end

--- @brief set color of all vertices
--- @param rgba rt.RGBA (or rt.HSVA)
function rt.VertexShape:set_color(rgba)
    if meta.is_hsva(rgba) then rgba = rt.hsva_to_rgba(rgba) end
    local r, g, b, a = rt.color_unpack(rgba)
    for i = 1, self:get_n_vertices() do
        self._native:setVertexAttribute(i, 3, r, g, b, a)
    end
end

--- @brief replace texture coordinates of all vertices
--- @param rectangle rt.AxisAlignedRectangle
function rt.VertexShape:set_texture_rectangle(rectangle, y, w, h)
    if meta.is_number(rectangle) then
        rectangle = rt.AABB(rectangle, y, w, h)
    end

    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY
    for i = 1, self:get_n_vertices() do
        local x, y = self:get_vertex_position(i)
        min_x = math.min(x, min_x)
        max_x = math.max(x, max_x)
        min_y = math.min(y, min_y)
        max_y = math.max(y, max_y)
    end

    local width = (max_x - min_x)
    local height = (max_y - min_y)
    for i = 1, self:get_n_vertices() do
        local x, y = self:get_vertex_position(i)
        self:set_vertex_texture_coordinate(i,
            (x - min_x) / (width / rectangle.width) + rectangle.x,
            (y - min_y) / (height / rectangle.height) + rectangle.y
        )
    end
end

--- @brief set texture
--- @param texture rt.Texture
function rt.VertexShape:set_texture(texture)
    if texture == nil then
        self._native:setTexture(nil)
    else
        self._native:setTexture(texture._native)
    end
end

--- @brief set draw mode
function rt.VertexShape:set_draw_mode(mode)
    self._native:setDrawMode(mode)
end

--- @overload rt.Drawable.draw
function rt.VertexShape:draw()
    if self._is_visible then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self._native)
    end
end

--- @brief
function rt.VertexShape:draw_instanced(n)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.drawInstanced(self._native, n)
end

--- @brief create vertex shape as rectangle
--- @param x Number in px
--- @param y Number in px
--- @param width Number in px
--- @param height Number in px
function rt.VertexRectangle(x, y, width, height)
    return rt.VertexShape({
        { x, y, 0 },
        { x + width, y, 0 },
        { x + width, y + height, 0 },
        { x, y + height }
    })
end

--- @brief
function rt.VertexRectangleSegments(thickness, vertices)
    local n_vertices = #vertices

    if not (n_vertices >= 4 and n_vertices % 2 == 0) then
        rt.error("In rt.VertexRectangleSegments: Need at least 2 vertices")
        return
    end

    function translate_point(point_x, point_y, distance, angle_dg)
        local rad = angle_dg * math.pi / 180
        return point_x + distance * math.cos(rad), point_y + distance * math.sin(rad)
    end

    local vertices_out = {}
    local vertex_map = {}
    for i = 1, n_vertices - 2, 2 do
        local a_x, a_y = vertices[i+0], vertices[i+1]
        local b_x, b_y = vertices[i+2], vertices[i+3]

        local ab_x, ab_y = b_x - a_x, b_y - a_y
        local angle = math.atan2(ab_y, ab_x)
        local angle_dg = ((angle * 180 / math.pi) + 360) % 360;

        local p1_x, p1_y = translate_point(a_x, a_y, thickness, angle_dg - 90)
        local p2_x, p2_y = translate_point(b_x, b_y, thickness, angle_dg - 90)
        local p3_x, p3_y = translate_point(b_x, b_y, thickness, angle_dg + 90)
        local p4_x, p4_y = translate_point(a_x, a_y, thickness, angle_dg + 90)

        for p in range(
            {p1_x, p1_y, 0},
            {p2_x, p2_y, 0},
            {p3_x, p3_y, 0},
            {p4_x, p4_y, 0}
        ) do
            table.insert(vertices_out, p)
        end

        local n = #vertices_out
        local p1_i = n-3
        local p2_i = n-2
        local p3_i = n-1
        local p4_i = n

        local n = #vertices_out
        for i in range(p1_i, p2_i, p3_i, p1_i, p3_i, p4_i) do
            table.insert(vertex_map, i)
        end
    end

    local out = rt.VertexShape(vertices_out)
    out:set_draw_mode(rt.MeshDrawMode.TRIANGLES)
    out:set_vertex_order(vertex_map)
    return out
end

--- @brief
function rt.VertexCircle(x, y, x_radius, y_radius, n_outer_vertices)
    y_radius = which(y_radius, x_radius)
    n_outer_vertices = which(n_outer_vertices, 8)
    local vertices = {}
    local indices = {}

    local step = 360 / n_outer_vertices
    for angle in step_range(0, 360, step) do
        local as_radians = rt.degrees_to_radians(angle)
        table.insert(vertices, {x + math.cos(as_radians) * x_radius, y + math.sin(as_radians) * y_radius, 0})
    end

    for i = 1, #vertices do
        table.insert(indices, i)
    end
    table.insert(indices, 1)

    local out = rt.VertexShape(vertices)
    out:set_draw_mode(rt.MeshDrawMode.TRIANGLE_FAN)
    out:set_vertex_order(indices)
    return out
end

--- @brief
function rt.VertexShape:reformat(...)
    local coords = {...}
    local vertex_i = 1
    for i = 1, #coords, 2 do
        self:set_vertex_position(vertex_i, coords[i], coords[i+1])
        vertex_i = vertex_i + 1
    end
end

--- @brief
function rt.VertexShape:reformat_texture_coordinates(...)
    local coords = {...}
    local vertex_i = 1
    for i = 1, #coords, 2 do
        self:set_vertex_texture_coordinate(vertex_i, coords[i], coords[i+1])
        vertex_i = vertex_i + 1
    end
end

--- @brief
function rt.VertexShape:reformat_vertex_positions(...)
    local coords = {...}
    local vertex_i = 1
    for i = 1, #coords, 2 do
        self:set_vertex_position(vertex_i, coords[i], coords[i+1])
        vertex_i = vertex_i + 1
    end
end

--- @brief
function rt.VertexShape:set_opacity(alpha)
    self._opacity = alpha
    for i = 1, self:get_n_vertices() do
        local r, g, b, a = self._native:getVertexAttribute(i, 3)
        self:set_vertex_color(i, r, g, b, math.max(a, self._opacity))
    end
end

--- @brief
function rt.VertexShape:get_centroid()
    local sum_x, sum_y = 0, 0
    local n = self:get_n_vertices()
    for i = 1, n do
        local x, y = self:get_vertex_position(i)
        sum_x = sum_x + x
        sum_y = sum_y + y
    end
    return sum_x / n, sum_y / n
end