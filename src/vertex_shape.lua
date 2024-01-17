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
        {name = "VertexTexCoord", format = "floatvec3"},
        {name = "VertexColor", format = "floatvec3"},
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
rt.VertexShape = meta.new_type("VertexShape", function(points)
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
        )
    }, rt.Drawable)
    out:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
    return out
end)

--- @brief get number of vertices
--- @return Number
function rt.VertexShape:get_n_vertices()
    return self._native:getVertexCount()
end

--- @brief set color of one vertex
--- @param i Number 1-based
--- @param rgba rt.RGBA
function rt.VertexShape:set_vertex_color(i, rgba)
    if meta.is_hsva(rgba) then rgba = rt.hsva_to_rgba(rgba) end
    self._native:setVertexAttribute(i, 3, rgba.r, rgba.g, rgba.b, rgba.a)
end

--- @brief get color of one vertex
--- @param i Number 1-based
--- @return rt.RGBA
function rt.VertexShape:get_vertex_color(i)
    local r, g, b, a
    r, g, b, a = self._native:getVertexAttribute(i, 3)
    return rt.RGBA(r, g, b, a)
end

--- @brief set vertex position
--- @param i Number 1-based
--- @param x Number in px
--- @param y Number in px
function rt.VertexShape:set_vertex_position(i, x, y, z)
    self._native:setVertexAttribute(i, 1, x, y, z)
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

    if not self:get_is_visible() then return end

    if self:get_is_visible() then
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
       rt.error("In rt.VertexLine: TODO")
    end

    local translate_by_angle = function (origin_x, origin_y, angle_dg)
        local angle_rad = rt.degrees(angle_dg):as_radians()
        return origin_x + math.cos(angle_rad) * thickness, origin_y + math.sin(angle_rad) * thickness
    end

    local vertices_out = {}

    for i = 1, n_vertices - 4, 1 do
        local a_x, a_y = vertices[i+0], vertices[i+1]
        local b_x, b_y = vertices[i+2], vertices[i+3]
        local c_x, c_y = vertices[i+4], vertices[i+5]

        local current_angle = 180
        if c_y ~= nil and c_y ~= nil then
            local a = math3d.vec2(b_x - a_x, b_y - a_y)
            local b = math3d.vec2(c_x - b_x, c_y - b_y)
            current_angle = rt.radians(math.atan(b.y - a.y, b.x - a.x)):as_degrees()
        end



        local x1, y1, x2, y2, x3, y3, x4, y4
        if (current_angle >= 0 + 45 and current_angle <= 90 + 45) or (current_angle >= 180 + 45 or current_angle <= 360 - 45) then
            -- horizontally oriented
            x1, y1 = translate_by_angle(a_x, a_y, -90)
            x2, y2 = translate_by_angle(b_x, b_y, -90)
            x3, y3 = translate_by_angle(b_x, b_y,  90)
            x4, y4 = translate_by_angle(a_x, a_y,  90)

            for p in range(
                    {x1, y1, 0},
                    {x2, y2, 0},
                    {x3, y3, 0}
            ) do
                table.insert(vertices_out, p)
            end

            for p in range(
                    {x1, y1, 0},
                    {x3, y3, 0},
                    {x4, y4, 0}
            ) do
                table.insert(vertices_out, p)
            end
        else
            -- vertically oriented

        end
    end

    local out = rt.VertexShape(vertices_out)
    out:set_draw_mode(rt.MeshDrawMode.TRIANGLES)
    return out
end

--- @brief test VertexShape
function rt.test.vertex_shape()
    error("TODO")
end
