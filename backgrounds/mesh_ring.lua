rt.Background.MESH_RING = meta.new_type("MESH_RING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.MESH_RING, {
        _mesh = nil, -- love.Mesh
        _center_x = 0,
        _center_y = 0,
        _data = {},

        _shapes = {},
        _colors = {},

        _n_outer_vertices = 16,
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

    self._shapes = {}
    local n_shapes = 0
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

                local shape = {}
                for vertex_i in values(tri) do
                    local pos = positions[vertex_i]
                    table.insert(shape, pos[1])
                    table.insert(shape, pos[2])
                end

                table.insert(shape, shape[1])
                table.insert(shape, shape[2])
                table.insert(self._shapes, shape)

                n_shapes = n_shapes + 1
            end
        end
    end

    -- generate colors
    for i = 1, n_shapes do
        local hue = (i - 1) / n_shapes
        local color = rt.lcha_to_rgba(rt.LCHA(0.8, 1, hue, 1))
        table.insert(self._colors, {rt.color_unpack(color)})
    end
end

--- @override
function rt.Background.MESH_RING:draw()
    love.graphics.push()
    love.graphics.translate(self._center_x, self._center_y)
    love.graphics.setLineWidth(1)

    for i, shape in ipairs(self._shapes) do
        love.graphics.setColor(table.unpack(self._colors[i]))
        love.graphics.polygon("fill", shape)
    end

    love.graphics.setColor(0, 0, 0, 1)
    for shape in values(self._shapes) do
        love.graphics.polygon("line", shape)
    end

    love.graphics.pop()
end
