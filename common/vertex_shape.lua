--- @class rt.SpriteBatchUsage
rt.SpriteBatchUsage = meta.new_enum({
    DYNAMIC = "dynamic",
    STATIC = "static",
    STREAM = "stream"
})

--- @class rt.MeshDrawMode
rt.MeshDrawMode = meta.new_enum({
    TRIANGLE_FAN = "fan",
    TRIANGLE_STRIP = "strip",
    TRIANGLES = "triangles",
    POINTS = "points"
})

--- @class rt.VertexAttribute
rt.VertexAttribute = meta.new_enum({
    POSITION = "VertexPosition",
    TEXTURE_COORDINATES = "VertexTexCoord",
    COLOR = "VertexColor"
})

if love.getVersion() >= 12 then
    rt.VertexFormat = {
        {name = "VertexPosition", format = "floatvec3"},
        {name = "VertexTexCoord", format = "floatvec2"},
        {name = "VertexColor", format = "floatvec4"},
    }
else
    rt.VertexFormat = {
        {"VertexPosition", "float", 3},
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
function rt.Vertex(x, y, z, texture_coordinate_x, texture_coordinate_y, color)
    if meta.is_nil(color) then
        color = rt.RGBA(1, 1, 1, 1)
    end
    return {
        x, y, z,
        texture_coordinate_x, texture_coordinate_y,
        color.r, color.g, color.b, color.a
    }
end

--- @class rt.VertexShape
--- @param vararg rt.Vector2
rt.VertexShape = meta.new_type("VertexShape", rt.Drawable, function(points)
    local vertices = {}
    for _, pos in pairs(points) do
        table.insert(vertices, rt.Vertex(pos[1], pos[2], pos[3], 0, 0))
    end

    local out = meta.new(rt.VertexShape, {
        _native = love.graphics.newMesh(
            rt.VertexFormat,
            vertices,
            rt.MeshDrawMode.TRIANGLE_FAN,
            rt.SpriteBatchUsage.DYNAMIC
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
        self._native:setVertexAttribute(i, 3, r, g, b, self._opacity)
    else
        local rgba = r_or_rgba
        if meta.is_hsva(rgba) then rgba = rt.hsva_to_rgba(rgba) end
        self._native:setVertexAttribute(i, 3, rgba.r, rgba.g, rgba.b, self._opacity)
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
function rt.VertexShape:set_vertex_position(i, x, y, z)
    self._native:setVertexAttribute(i, 1, x, y, which(z, 0))
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
    for i = 1, self:get_n_vertices() do
        self:set_vertex_color(i, rgba)
    end
end

--- @brief replace texture coordinates of all vertices
--- @param rectangle rt.AxisAlignedRectangle
function rt.VertexShape:set_texture_rectangle(rectangle)
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
    if not meta.is_nil(texture) then
        self._native:setTexture(texture._native)
    else
        self._native:setTexture(nil)
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
function rt.VertexLine(thickness, ...)
    local vertices = {...}
    local n_vertices = _G._select('#', ...)

    if not (n_vertices >= 4 and n_vertices % 2 == 0) then
        rt.error("In rt.VertexLine: Need at least 2 vertices")
    end

    local function translate_point(point, distance, angle_dg)
        local rad = angle_dg * math.pi / 180
        return math3d.vec2(point.x + distance * math.cos(rad), point.y + distance * math.sin(rad))
    end

    function intersect(line1_a, line1_b, line2_a, line2_b)
        local a = {
            math3d.vec3(line1_a.x, line1_a.y, 0),
            math3d.vec3(line1_b.x, line1_b.y, 0)
        }

        local b = {
            math3d.vec3(line2_a.x, line2_a.y, 0),
            math3d.vec3(line2_b.x, line2_b.y, 0)
        }

        local out, distance = math3d.intersect.line_line(a, b, nil)
        return math3d.vec2(out[1].x, out[1].y)
    end

    local vertices_out = {}
    local vertex_map = {}

    for i = 1, n_vertices - 2, 2 do
        local a = math3d.vec2(vertices[i+0], vertices[i+1])
        local b = math3d.vec2(vertices[i+2], vertices[i+3])
        local c = math3d.vec2(vertices[i+4], vertices[i+5])

        local ab = math3d.vec2(b.x - a.x, b.y - a.y)
        local bc = math3d.vec2(c.x - b.x, c.y - b.y)

        local ab_angle = math.atan2(ab.y, ab.x)
        local ab_angle_dg = ((ab_angle * 180 / math.pi) + 360) % 360;

        local bc_angle = math.atan2(bc.y, bc.x)
        local bc_angle_dg = ((bc_angle * 180 / math.pi) + 360) % 360;

        if i == 1 then
            local last_vertex_up = math3d.vec2(translate_point(a, thickness, ab_angle_dg - 90))
            local last_vertex_down = math3d.vec2(translate_point(a, thickness, ab_angle_dg + 90))

            table.insert(vertices_out, {last_vertex_up.x, last_vertex_up.y, 0})
            table.insert(vertices_out, {last_vertex_down.x, last_vertex_down.y, 0})
        end

        -- create two edges parallel to ab and bc, shifted by thickness up/down, then find intersection to solve for vertices

        local up_offset = -90
        local ab_start_up = translate_point(a, thickness, ab_angle_dg + up_offset)
        local ab_end_up = translate_point(b, thickness, ab_angle_dg + up_offset)
        local bc_start_up = translate_point(b, thickness, bc_angle_dg + up_offset)
        local bc_end_up = translate_point(c, thickness, bc_angle_dg + up_offset)

        local down_offset = 90
        local ab_start_down = translate_point(a, thickness, ab_angle_dg + down_offset)
        local ab_end_down = translate_point(b, thickness, ab_angle_dg + down_offset)
        local bc_start_down = translate_point(b, thickness, bc_angle_dg + down_offset)
        local bc_end_down = translate_point(c, thickness, bc_angle_dg + down_offset)

        local up_intersect, down_intersect;

        if ab.x == bc.x or ab.y == bc.y then
            -- if in line, infinitely many intersections
            up_intersect = ab_end_up
            down_intersect = ab_end_down
        else
            -- otherwise, intersect always exists because pre-shifted lines shared a vertex
            up_intersect = intersect(ab_start_up, ab_end_up, bc_start_up, bc_end_up)
            down_intersect = intersect(ab_start_down, ab_end_down, bc_start_down, bc_end_down)
        end

        -- last node, since c does not exist
        if i >= n_vertices - 3 then
            up_intersect = math3d.vec2(translate_point(b, thickness, ab_angle_dg - 90))
            down_intersect = math3d.vec2(translate_point(b, thickness, ab_angle_dg + 90))
        end

        table.insert(vertices_out, {up_intersect.x, up_intersect.y, 0})
        table.insert(vertices_out, {down_intersect.x, down_intersect.y, 0})

        local n = #vertices_out
        local p1, p2, p3, p4 = n-3, n-1, n, n-2

        for i in range(
            p1, p2, p3,
            p1, p3, p4
        ) do
            table.insert(vertex_map, i)
        end
    end

    local out = rt.VertexShape(vertices_out)
    out:set_draw_mode(rt.MeshDrawMode.TRIANGLES)
    out:set_vertex_order(vertex_map)
    return out
end

--- @brief
function rt.VertexRectangleSegments(thickness, vertices)
    local n_vertices = #vertices

    if not (n_vertices >= 4 and n_vertices % 2 == 0) then
        rt.error("In rt.VertexRectangleSegments: Need at least 2 vertices")
    end

    function translate_point(point, distance, angle_dg)
        local rad = angle_dg * math.pi / 180
        return math3d.vec2(point.x + distance * math.cos(rad), point.y + distance * math.sin(rad))
    end

    local vertices_out = {}
    local vertex_map = {}
    for i = 1, n_vertices - 2, 2 do
        local a = math3d.vec2(vertices[i+0], vertices[i+1])
        local b = math3d.vec2(vertices[i+2], vertices[i+3])

        local ab = math3d.vec2(b.x - a.x, b.y - a.y)
        local angle = math.atan2(ab.y, ab.x)
        local angle_dg = ((angle * 180 / math.pi) + 360) % 360;

        local p1 = translate_point(a, thickness, angle_dg - 90)
        local p2 = translate_point(b, thickness, angle_dg - 90)
        local p3 = translate_point(b, thickness, angle_dg + 90)
        local p4 = translate_point(a, thickness, angle_dg + 90)

        for p in range(
            {p1.x, p1.y, 0},
            {p2.x, p2.y, 0},
            {p3.x, p3.y, 0},
            {p4.x, p4.y, 0}
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
        self:set_vertex_color(i, r, g, b, a) -- applies alpha
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

--- @brief test VertexShape
function rt.test.vertex_shape()
    error("TODO")
end
