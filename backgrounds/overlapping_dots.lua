rt.Background.OVERLAPPING_DOTS = meta.new_type("OVERLAPPING_DOTS", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.OVERLAPPING_DOTS, {
        _circle_mesh = nil, -- rt.VertexShape
        _n_outer_vertices = 5,
        _min_radius = 10,
        _max_radius = 14,
        _n_instances = 0, -- set during size_allocate
        _data = nil, -- love.GraphicsBuffer
        _shader = rt.Shader("backgrounds/overlapping_dots.glsl"),
        _elapsed = 0
    })
end)

--- @override
function rt.Background.OVERLAPPING_DOTS:realize()
    local x_radius, y_radius = 1, 1
    local step = 2 * math.pi / self._n_outer_vertices

    local data = {
        {0, 0, 0, 0, rt.color_unpack(rt.Palette.GRAY_1)}
    }

    local r, g, b, a = rt.color_unpack(rt.Palette.GRAY_3)
    for angle = 0, 2 * math.pi, step do
        table.insert(data, {
            0 + math.cos(angle) * x_radius, 0 + math.sin(angle) * y_radius, 0, 0, r, g, b, 1
        })
    end

    local map = {}
    for outer_i = 2, self._n_outer_vertices do
        for i in range(1, outer_i, outer_i + 1) do
            table.insert(map, i)
        end
    end

    for i in range(self._n_outer_vertices + 1, 1, 2) do
        table.insert(map, i)
    end

    self._mesh = rt.VertexShape(data, rt.MeshDrawMode.TRIANGLES)
    self._mesh._native:setVertexMap(map)
end

--- @override
function rt.Background.OVERLAPPING_DOTS:size_allocate(x, y, width, height)
    local n_cols = math.ceil(width / self._max_radius) + 2
    local n_rows = math.ceil(height / self._max_radius) + 2
    self._n_instances = n_rows * n_cols

    local format = self._shader:get_buffer_format("instance_data_buffer")
    local instance_data_buffer = rt.GraphicsBuffer(format, self._n_instances)

    local data = {}
    local cell_w = self._max_radius
    local cell_h = cell_w
    for col_i = 1, n_cols do
        for row_i = 1, n_rows do
            local cell_x, cell_y = (col_i - 1) * cell_w, (row_i - 1) * cell_h
            table.insert(data, {
                cell_x + 0.5 * cell_w, cell_y + 0.5 * cell_h,
                mix(self._min_radius, self._max_radius, math.random()), -- radius
                mix(-math.pi, math.pi, math.random()), -- rotation
                math.random(), -- hue
            })
        end
    end

    data = rt.random.shuffle(data)
    instance_data_buffer:replace_data(data)
    self._shader:send("instance_data_buffer", instance_data_buffer._native)
    self._shader:send("n_instances", self._n_instances)
end

--- @override
function rt.Background.OVERLAPPING_DOTS:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function rt.Background.OVERLAPPING_DOTS:draw()
    love.graphics.setColor(rt.color_unpack(rt.Palette.GRAY_9))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    self._shader:bind()
    self._mesh:draw_instanced(self._n_instances)
    self._shader:unbind()
end
