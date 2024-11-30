rt.Background.MESH_RING = meta.new_type("MESH_RING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.MESH_RING, {
        _mesh = nil, -- love.Mesh
        _center_x = 0,
        _center_y = 0,
        _data = {},
        _lines = {},

        _n_outer_vertices = 8,
        _n_rings = 4,

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
    if love.keyboard.isDown("space") then
        self._elapsed = self._elapsed + delta
    end

    self._data = {}
    self._lines = {}

    -- generate positions
    local positions = {}
    local x_radius = self._radius_x
    local y_radius = self._radius_y

    local n_rings = self._n_rings
    local n_outer_vertices = self._n_outer_vertices
    local step = 2 * math.pi / (n_outer_vertices - 1)

    for ring_i = 1, n_rings do
        local fraction = (ring_i - 1) / n_rings
        local ring_x_radius = x_radius * fraction
        local ring_y_radius = y_radius * fraction

        local outline = {} -- lines around the perimeter of each ring

        local angle_offset = (ring_i / n_rings) * 2 * math.pi / 2 + ((ring_i + 1) / n_rings) * (self._elapsed)
        for i = 1, n_outer_vertices, 1 do
            local position_x = 0 + math.cos((i - 1) * step + angle_offset) * ring_x_radius
            local position_y = 0 + math.sin((i - 1) * step + angle_offset) * ring_y_radius
            table.insert(positions, { position_x, position_y })

            table.insert(outline, position_x)
            table.insert(outline, position_y)
        end

        table.insert(outline, outline[1])
        table.insert(outline, outline[2])
        table.insert(self._lines, outline)
    end

    local n_triangles = n_outer_vertices * (n_rings - 1)
    local triangle_i = 0 -- sic

    for outer_i = 1, n_outer_vertices do
        local line = {}
        for ring_i = 1, n_rings do
            if ring_i < n_rings then
                -- generate triangles
                for tri in range({
                    (ring_i - 1) * n_outer_vertices + outer_i,
                    (ring_i - 1) * n_outer_vertices + outer_i + 1,
                    (ring_i - 1 + 1) * n_outer_vertices + outer_i
                }, {
                    (ring_i - 1) * n_outer_vertices + outer_i + 1,
                    (ring_i - 1 + 1) * n_outer_vertices + outer_i,
                    (ring_i - 1 + 1) * n_outer_vertices + outer_i + 1
                }) do
                    local color = rt.lcha_to_rgba(rt.LCHA(0.8, 1, triangle_i / n_triangles, 1))
                    for vertex_i in values(tri) do
                        if vertex_i < sizeof(positions) then
                            local x, y = table.unpack(positions[vertex_i])
                            table.insert(self._data, {
                                x, y, color.r, color.g, color.b, color.a
                            })
                        end
                    end
                end
                triangle_i = triangle_i + 1
            end

            -- generate perpendicular lines
            local linear_i = (ring_i - 1) * n_outer_vertices + outer_i
            for x in values(positions[linear_i]) do
                table.insert(line, x)
            end
        end

        --table.insert(self._lines, line)
    end

    --[[
    for outer_i = 1, n_outer_vertices do
        for ring_i = 1, n_rings - 1 do
            local line = {}
            for position_i in range(
                (ring_i - 1) * n_outer_vertices + outer_i,
                (ring_i - 1) * n_outer_vertices + outer_i + 1,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i,
                (ring_i - 1 + 1) * n_outer_vertices + outer_i + 1
            ) do
                local position = positions[position_i]
                table.insert(line, position[1])
                table.insert(line, position[2])
            end
            table.insert(self._lines, line)
        end
    end
    ]]--

    if self._mesh == nil then
        self._mesh = love.graphics.newMesh({
            {name = "VertexPosition", format = "floatvec2"},
            {name = "VertexColor", format = "floatvec4"},
        }, self._data, rt.MeshDrawMode.TRIANGLES, rt.GraphicsBufferUsage.STREAM)
    else
        self._mesh:setVertices(self._data)
    end

    self._is_ready = true
end

--- @override
function rt.Background.MESH_RING:draw()
    if self._is_ready ~= true then return end

    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    --love.graphics.setWireframe(true)
    love.graphics.push()
    love.graphics.translate(self._center_x, self._center_y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._mesh)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(0, 0, 0, 1)
    for line in values(self._lines) do
        love.graphics.line(line)
    end
    love.graphics.pop()
end
