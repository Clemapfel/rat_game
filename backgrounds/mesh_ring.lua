rt.Background.MESH_RING = meta.new_type("MESH_RING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.MESH_RING, {
        _triangles = {}, -- Table<Array<3>>
        _colors = {},    -- Table<Array<4>>
        _n_outer_vertices = 64,
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
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local m = rt.settings.margin_unit
    local radius = math.min(width, height) / 2 - 2 * m

    self._center_x = center_x
    self._center_y = center_y
    self._x_radius = radius
    self._y_radius = radius
    self._thickness = 6 * m

    self:update(0)
end

--- @override
function rt.Background.MESH_RING:update(delta)
    self._elapsed = self._elapsed + delta

    local fraction = (math.sin(self._elapsed) + 1) / 2
    local inner_angle_offset = fraction * math.pi
    local outer_angle_offset = 0.5 * inner_angle_offset

    local vertices = {}
    local step = 2 * math.pi / self._n_outer_vertices
    local n_vertices = 0
    for angle = 0, 2 * math.pi + step, step do
        local outer_x = self._center_x + math.cos(angle + outer_angle_offset) * (self._x_radius)
        local outer_y = self._center_y + math.sin(angle + outer_angle_offset) * (self._y_radius)

        local inner_x = self._center_x + math.cos(angle + inner_angle_offset) * (self._x_radius - self._thickness)
        local inner_y = self._center_y + math.sin(angle + inner_angle_offset) * (self._y_radius - self._thickness)

        table.insert(vertices, {outer_x, outer_y})
        table.insert(vertices, {inner_x, inner_y})

        n_vertices = n_vertices + 2
    end

    self._triangles = {}
    self._n_triangles = 0
    for i = 1, n_vertices - 2 do
        local tri_a = {}
        for index in range(
            i, i + 1, i + 2
        ) do
            local vertex = vertices[index]
            table.insert(tri_a, vertex[1])
            table.insert(tri_a, vertex[2])
        end

        table.insert(self._triangles, tri_a)
        self._n_triangles = self._n_triangles + 1
    end

    self._colors = {}
    local hue = 0
    for i = 1, self._n_triangles do
        local color = rt.lcha_to_rgba(rt.LCHA(0.75, 1, hue, 1))
        table.insert(self._colors, { color.r, color.g, color.b, color.a })
        hue = hue + 1 / self._n_triangles
    end
end

--- @override
function rt.Background.MESH_RING:draw()
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineWidth(2)
    for i = 1, self._n_triangles do
        love.graphics.setColor(table.unpack(self._colors[i]))
        love.graphics.polygon("fill", self._triangles[i])
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.polygon("line", self._triangles[i])
    end
end
