rt.Background.MESH_RING = meta.new_type("MESH_RING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.MESH_RING, {
        _mesh = nil, -- love.Mesh
        _center_x = 0,
        _center_y = 0,
        _data = {},
        _lines = {},

        _n_outer_vertices = 6,
        _n_rings = 10,

        _elapsed = 0,
        _duration = 5
    })
end)

--- @override
function rt.Background.MESH_RING:realize()
    -- noop
end

--- @override
function rt.Background.MESH_RING:size_allocate(x, y, width, height)
    self._center_x = x + 0.5 * width
    self._center_y = y + 0.5 * height
    local m = rt.settings.margin_unit
    self._radius_x = math.min(width, height) / 2
    self._radius_y = self._radius_x
end

--- @override
function rt.Background.MESH_RING:update(delta)
    self._elapsed = self._elapsed + delta

    self._data = {}
    self._lines = {}

    local x_radius = self._radius_x
    local y_radius = self._radius_y

    local n_rings = self._n_rings
    local n_outer_vertices = self._n_outer_vertices
    local step = 2 * math.pi / n_outer_vertices

    local positions = {}
    for ring_i = 1, n_rings do
        local fraction = (ring_i - 1) / n_rings
        local ring_x_radius = x_radius * fraction
        local ring_y_radius = y_radius * fraction

        local extra = 0
        if ring_i == n_rings then extra = 1 end -- close last triangle

        local angle_offset = 0 --(ring_i / n_rings) * 2 * math.pi / 2 + ((ring_i + 1) / n_rings) * (self._elapsed)

        local line = {} -- circular line
        for i = 1, n_outer_vertices + extra, 1 do
            local color = rt.lcha_to_rgba(rt.LCHA(0.8, 1, fract(i / n_outer_vertices / 3) * 3, 1))
            local position_x = 0 + math.cos((i - 1) * step + angle_offset) * ring_x_radius
            local position_y = 0 + math.sin((i - 1) * step + angle_offset) * ring_y_radius
            table.insert(self._data, {
                position_x, position_y, color.r, color.g, color.b, color.a
            })

            table.insert(positions, { position_x, position_y })
            table.insert(line, position_x)
            table.insert(line, position_y)
        end

        table.insert(line, line[1])
        table.insert(line, line[2])
        --table.insert(self._lines, line)
    end

    -- perpendicular lines
    for i = 1, n_outer_vertices do
        local line = {}
        for ring_i = 1, n_rings do
            local pos = positions[(ring_i - 1) * n_outer_vertices + i]
            table.insert(line, pos[1])
            table.insert(line, pos[2])
        end
        --table.insert(self._lines, line)
    end

    local vertex_map = {}
    for outer_i = 1, n_outer_vertices do
        for ring_i = 1, n_rings - 1 do
            local line = {}

            local color = rt.lcha_to_rgba(rt.LCHA(0.8, 1, fract(ring_i / n_outer_vertices, 1)))

            for vertex_i in range(
                (ring_i - 1) * n_outer_vertices + outer_i,
                (ring_i - 1) * n_outer_vertices + outer_i + 1,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i
            ) do
                table.insert(vertex_map, vertex_i)

                local pos = positions[vertex_i]
                table.insert(line, pos[1])
                table.insert(line, pos[2])
            end

            table.insert(line, line[1])
            table.insert(line, line[2])
            table.insert(self._lines, line)

            local line = {}
            for vertex_i in range(
                (ring_i - 1) * n_outer_vertices + outer_i + 1,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i + 1
            ) do
                table.insert(vertex_map, vertex_i)

                local pos = positions[vertex_i]
                table.insert(line, pos[1])
                table.insert(line, pos[2])
            end

            table.insert(line, line[1])
            table.insert(line, line[2])
            table.insert(self._lines, line)
        end
    end

    if self._mesh == nil then
        self._mesh = love.graphics.newMesh({
            {name = "VertexPosition", format = "floatvec2"},
            {name = "VertexColor", format = "floatvec4"},
        }, self._data, rt.MeshDrawMode.TRIANGLE_FAN, rt.GraphicsBufferUsage.STREAM)

    else
        self._mesh:setVertices(self._data)
    end
end

--- @override
function rt.Background.MESH_RING:update(delta)
    self._elapsed = self._elapsed + delta

    -- generate positions
    local positions = {}
    local x_radius = self._radius_x
    local y_radius = self._radius_y

    local n_rings = self._n_rings
    local n_outer_vertices = self._n_outer_vertices
    local step = 2 * math.pi / n_outer_vertices

    for ring_i = 1, n_rings do
        local fraction = (ring_i - 1) / n_rings
        local ring_x_radius = x_radius * fraction
        local ring_y_radius = y_radius * fraction

        local extra = 0
        if ring_i == n_rings then extra = 1 end -- close last triangle

        local angle_offset = (ring_i / n_rings) * 2 * math.pi / 2 + ((ring_i + 1) / n_rings) * (self._elapsed)
        for i = 1, n_outer_vertices + extra, 1 do
            local position_x = 0 + math.cos((i - 1) * step + angle_offset) * ring_x_radius
            local position_y = 0 + math.sin((i - 1) * step + angle_offset) * ring_y_radius
            table.insert(positions, { position_x, position_y })
        end
    end

    -- generate lines and vertex map
    self._lines = {}
    local vertex_map = {}
    for outer_i = 1, n_outer_vertices do
        for ring_i = 1, n_rings - 1 do
            for tri in range({
                (ring_i - 1) * n_outer_vertices + outer_i,
                (ring_i - 1) * n_outer_vertices + outer_i + 1,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i
            }, {
                (ring_i - 1) * n_outer_vertices + outer_i + 1,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i + 1
            }) do

                local line = {}
                for vertex_i in values(tri) do
                    local pos = positions[vertex_i]
                    table.insert(line, pos[1])
                    table.insert(line, pos[2])

                    if self._mesh == nil then
                        table.insert(vertex_map, vertex_i)
                    end
                end

                table.insert(line, line[1])
                table.insert(line, line[2])
                table.insert(self._lines, line)
            end
        end
    end

    -- generate colors
    self._data = {}
    for ring_i = 1, n_rings do
        local hue = (ring_i - 1) / n_rings
        local color = rt.lcha_to_rgba(rt.LCHA(0.8, 1, hue, 1))
        for vertex_i = 1, n_outer_vertices + ternary(ring_i == n_rings, 1, 0) do
            local position_i = (ring_i - 1) * n_outer_vertices + vertex_i
            self._data[position_i] = {
                positions[position_i][1], positions[position_i][2],
                color.r, color.g, color.b, color.a
            }
        end
    end

    if self._mesh == nil then
        self._mesh = love.graphics.newMesh({
            {name = "VertexPosition", format = "floatvec2"},
            {name = "VertexColor", format = "floatvec4"},
        }, self._data, rt.MeshDrawMode.TRIANGLES, rt.GraphicsBufferUsage.STREAM)
        self._mesh:setVertexMap(vertex_map)
    else
        self._mesh:setVertices(self._data)
    end
end

--- @override
function rt.Background.MESH_RING:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    --love.graphics.setWireframe(true)
    love.graphics.push()
    love.graphics.translate(self._center_x, self._center_y)
    love.graphics.setColor(1, 1, 1, 1)
    if self._mesh ~= nil then
        love.graphics.draw(self._mesh)
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(0, 0, 0, 1)
    for line in values(self._lines) do
        love.graphics.line(line)
    end
    love.graphics.pop()
end
