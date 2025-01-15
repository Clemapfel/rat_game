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

rt.VertexFormat = {
    {name = "VertexPosition", format = "floatvec2"},
    {name = "VertexTexCoord", format = "floatvec2"},
    {name = "VertexColor", format = "floatvec4"},
}

--- @class rt.VertexShape
rt.VertexShape = meta.new_type("VertexShape", rt.Drawable, function(data, draw_mode, format)
    local out = meta.new(rt.VertexShape, {
        _native = love.graphics.newMesh(
            which(format, rt.VertexFormat),
            data,
            which(draw_mode, rt.MeshDrawMode.TRIANGLE_FAN),
            rt.GraphicsBufferUsage.DYNAMIC
        ),
        _r = 1,
        _g = 1,
        _b = 1,
        _opacity = 1
    })
    return out
end)

--- @class rt.VertexRectangle
rt.VertexRectangle = function(x, y, width, height)
    local data = {
        {x + 0 * width, y + 0 * height, 0, 0, 1, 1, 1, 1},
        {x + 1 * width, y + 0 * height, 1, 0, 1, 1, 1, 1},
        {x + 1 * width, y + 1 * height, 1, 1, 1, 1, 1, 1},
        {x + 0 * width, y + 1 * height, 0, 1, 1, 1, 1, 1}
    }

    return meta.new(rt.VertexShape, {
        _native = love.graphics.newMesh(
            rt.VertexFormat,
            data,
            rt.MeshDrawMode.TRIANGLE_FAN,
            rt.GraphicsBufferUsage.STATIC
        ),
        _r = 1,
        _g = 1,
        _b = 1,
        _opacity = 1
    })
end

do
    local _n_outer_vertices_to_vertex_map = {}

    --- @class rt.VertexCircle
    rt.VertexCircle = function(center_x, center_y, x_radius, y_radius, n_outer_vertices)
        y_radius = which(y_radius, x_radius)
        n_outer_vertices = which(n_outer_vertices, 8)
        local data = {
            {center_x, center_y, 0.5, 0.5, 1, 1, 1, 1},
        }

        local step = 2 * math.pi / n_outer_vertices
        for angle = 0, 2 * math.pi, step do
            table.insert(data, {
                center_x + math.cos(angle) * x_radius,
                center_y + math.sin(angle) * y_radius,
                0.5 + math.cos(angle) * 0.5,
                0.5 + math.sin(angle) * 0.5,
                1, 1, 1, 1
            })
        end

        local map = {}
        for outer_i = 2, n_outer_vertices do
            for i in range(1, outer_i, outer_i + 1) do
                table.insert(map, i)
            end
        end

        for i in range(n_outer_vertices + 1, 1, 2) do
            table.insert(map, i)
        end

        local native = love.graphics.newMesh(
            rt.VertexFormat,
            data,
            rt.MeshDrawMode.TRIANGLES,
            rt.GraphicsBufferUsage.STATIC
        )
        native:setVertexMap(map)

        return meta.new(rt.VertexShape, {
            _native = native,
            _r = 1,
            _g = 1,
            _b = 1,
            _opacity = 1
        })
    end
end

--- @override
function rt.VertexShape:draw(...)
    love.graphics.setColor(self._r, self._g, self._b, self._opacity)
    love.graphics.draw(self._native, ...)
end

--- @brief
function rt.VertexShape:draw_instanced(n_instances)
    love.graphics.setColor(self._r, self._g, self._b, self._opacity)
    love.graphics.drawInstanced(self._native, n_instances)
end

--- @brief
function rt.VertexShape:reformat(...)
    local n = select("#", ...)
    local vertex_i = 1
    for i = 1, n, 2 do
        local x, y = select(i, ...), select(i + 1, ...)
        self._native:setVertexAttribute(vertex_i, 1, x, y)
        vertex_i = vertex_i + 1
    end
end

--- @brief
function rt.VertexShape:reformat_texture_coordinates(...)
    local n = select("#", ...)
    local vertex_i = 1
    for i = 1, n, 2 do
        local x, y = select(i, ...), select(i + 1, ...)
        self._native:setVertexAttribute(vertex_i, 2, x, y)
        vertex_i = vertex_i + 1
    end
end

--- @brief
function rt.VertexShape:set_vertex_position(i, x, y)
    self._native:setVertexAttribute(i, 1, x, y)
end

--- @brief
function rt.VertexShape:set_vertex_texture_coordinate(i, u, v)
    self._native:setVertexAttribute(i, 2, u, v)
end

--- @brief
function rt.VertexShape:set_vertex_color(i, r_or_color, g, b, a)
    local r = r_or_color
    if meta.is_rgba(r_or_color) then
        r = r_or_color.r
        g = r_or_color.g
        b = r_or_color.b
        a = r_or_color.a
    end

    self._native:setVertexAttribute(i, 3, r, g, b, a)
end

--- @brief
function rt.VertexShape:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.VertexShape:set_color(color, g, b, a)
    if meta.is_number(color) then
        self._r, self._g, self._b = color, g, b
        self._opacity = math.min(self._opacity, a)
    else
        if meta.is_hsva(color) then
            color = rt.hsva_to_rgba(color)
        elseif meta.is_lcha(color) then
            color = rt.lcha_to_rgba(color)
        end

        self._r, self._g, self._b = color.r, color.g, color.b
        self._opacity = math.min(self._opacity, color.a)
    end
end

--- @brief
function rt.VertexShape:set_texture(texture)
    self._native:setTexture(texture._native)
end

--- @brief
function rt.VertexShape:get_n_vertices()
    return self._native:getVertexCount()
end

--- @brief
function rt.VertexShape:replace_data(data)
    self._native:setVertices(data)
end
