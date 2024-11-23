rt.Background.MESH_RING = meta.new_type("MESH_RING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.MESH_RING, {
        _mesh = nil, -- love.Mesh
        _mesh_format = {
            {name = "VertexPosition", format = "floatvec2"},
            {name = "VertexColor", format = "floatvec4"},
        },
        _center_x = 0,
        _center_y = 0,
        _x_radius = 0,
        _y_radius = 0,
        _thickness = 0,
        _margin = 0,
        _n_outer_vertices = 64,
        _vertices = {},

        _elapsed = 0
    })
end)

--- @override
function rt.Background.MESH_RING:realize()

end

--- @override
function rt.Background.MESH_RING:size_allocate(x, y, width, height)
    self._center_x, self._center_y = x + 0.5 * width,y + 0.5 * height
    self._x_radius, self._y_radius = 0.5 * height, 0.5 * height
    self._thickness = 0.1 * height
    self._margin = 0.05 * height
    self:update(0)
end

--- @override
function rt.Background.MESH_RING:update(delta)
    self._elapsed = self._elapsed + delta

    local vertices = {}
    local points = {}
    local outer_color = rt.RGBA(1, 1, 1, 1)
    local inner_color_factor = 0.7
    local inner_color = rt.RGBA(inner_color_factor, inner_color_factor, inner_color_factor, 1)

    local step = 2 * math.pi / self._n_outer_vertices
    local n_vertices = 0
    for angle = 0, 2 * math.pi, step do
        local outer_x = self._center_x + math.cos(angle) * (self._x_radius - self._margin)
        local outer_y = self._center_y + math.sin(angle) * (self._y_radius - self._margin)

        table.insert(vertices, {
            outer_x, outer_y,
            0, 0,
            outer_color.r, outer_color.g, outer_color.b, outer_color.a
        })

        local inner_x = self._center_x + math.cos(angle) * (self._x_radius - self._thickness - self._margin)
        local inner_y = self._center_y + math.sin(angle) * (self._y_radius - self._thickness - self._margin)

        table.insert(vertices, {
            inner_x, inner_y,
            0, 0,
            inner_color.r, inner_color.g, inner_color.b, inner_color.a
        })

        n_vertices = n_vertices + 2
    end

    if self._mesh == nil then
        self._mesh = love.graphics.newMesh(vertices, rt.MeshDrawMode.TRIANGLES)

        local vertex_map = {}
        for i = 1, n_vertices - 3 do
            for index in range(
                i, i + 1, i + 2,
                i + 1, i + 2, i + 3
            ) do
                table.insert(vertex_map, index)
            end
        end

        for index in range(
            n_vertices - 1, n_vertices, 1,
            n_vertices, 1, 2
        ) do
            table.insert(vertex_map, index)
        end

        self._mesh:setVertexMap(vertex_map)
    else
        self._mesh:setVertices(vertices)
    end

end

--- @override
function rt.Background.MESH_RING:draw()
    if self._mesh == nil then return end
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    --love.graphics.draw(self._mesh)
    love.graphics.line(self._vertices)
end
