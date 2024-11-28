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
        _n_outer_vertices = 32,
        _vertices = {},

        _animation_a = rt.TimedAnimation(3, 0, 1, rt.InterpolationFunctions.SINE_WAVE),
        _animation_b = rt.TimedAnimation(30, 0, 1, rt.InterpolationFunctions.SINE_WAVE),
        _elapsed = 0
    })
end)

--- @override
function rt.Background.MESH_RING:realize()

end

--- @override
function rt.Background.MESH_RING:size_allocate(x, y, width, height)
    self._margin = 0.05 * height
    self._center_x, self._center_y = x + 0.5 * width,y + 0.5 * height
    self._x_radius, self._y_radius = 0.5 * height - self._margin, 0.5 * height - self._margin
    self._thickness = 0.1 * height
    self:update(0)
end

--- @override
function rt.Background.MESH_RING:update(delta)
    if love.keyboard.isDown("space") then
        self._animation_a:update(delta)
        self._animation_b:update(delta)
        self._elapsed = self._elapsed + delta
    end

    local angle_magnitude = math.pi
    local outer_angle_offset = -1 * self._animation_b:get_value() * angle_magnitude
    local outer_radius_offset = 0

    local inner_angle_offset = self._animation_b:get_value() * angle_magnitude
    local inner_radius_offset = self._animation_b:get_value() * - 20 * (self._x_radius - self._thickness)

    local vertices = {}
    local points = {}
    local outer_color = rt.RGBA(1, 1, 1, 1)
    local inner_color_factor = 0.7
    local inner_color = rt.RGBA(inner_color_factor, inner_color_factor, inner_color_factor, 1)

    local center_x, center_y, x_radius, y_radius, margin, thickness = self._center_x, self._center_y, self._x_radius, self._y_radius, self._thickness, self._margin

    local step = 2 * math.pi / self._n_outer_vertices
    local n_vertices = 0
    for angle = 0, 2 * math.pi + step, step do
        local outer_x = self._center_x + math.cos(angle + outer_angle_offset) * (self._x_radius + outer_radius_offset)
        local outer_y = self._center_y + math.sin(angle + outer_angle_offset) * (self._y_radius + outer_radius_offset)

        local inner_x = self._center_x + math.cos(angle + inner_angle_offset) * (self._x_radius - self._thickness + inner_radius_offset)
        local inner_y = self._center_y + math.sin(angle + inner_angle_offset) * (self._y_radius - self._thickness + inner_radius_offset)

        table.insert(vertices, {outer_x, outer_y})
        table.insert(vertices, {inner_x, inner_y})

        n_vertices = n_vertices + 2
    end

    self._vertices = {}
    for i = 1, n_vertices - 3 do
        for index in range(
            i, i + 1, i + 2, i,
            i + 1, i + 2, i + 3, i + 1
        ) do
            local vertex = vertices[index]
            table.insert(self._vertices, vertex[1])
            table.insert(self._vertices, vertex[2])
        end
    end

end

--- @override
function rt.Background.MESH_RING:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    --love.graphics.draw(self._mesh)
    love.graphics.setLineJoin(rt.LineJoin.BEVEL)
    love.graphics.line(self._vertices)

end
