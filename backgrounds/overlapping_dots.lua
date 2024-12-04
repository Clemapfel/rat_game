rt.Background.OVERLAPPING_DOTS = meta.new_type("OVERLAPPING_DOTS", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.OVERLAPPING_DOTS, {
        _circle_mesh = nil, -- rt.VertexShape
        _n_outer_vertices = 5,
        _cell_radius = 12,
        _max_radius = 40,
        _n_instances = 0, -- set during size_allocate
        _data = nil, -- love.GraphicsBuffer
        _data_swap = nil, -- "

        _radius_denominator = 2^17,
        _render_shader = rt.Shader("backgrounds/overlapping_dots_render.glsl"),
        _update_shader = rt.ComputeShader("backgrounds/overlapping_dots_update.glsl"),
        _sort_shader = rt.ComputeShader("backgrounds/overlapping_dots_sort.glsl"),
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
    local n_cols = math.ceil(width / self._cell_radius) + 2
    local n_rows = math.ceil(height / self._cell_radius) + 2
    self._n_instances = n_rows * n_cols

    local format = self._render_shader:get_buffer_format("instance_data_buffer")
    local instance_data_buffer = rt.GraphicsBuffer(format, self._n_instances)
    local instance_data_swap_buffer = rt.GraphicsBuffer(format, self._n_instances)

    local data = {}
    local cell_w = self._cell_radius
    local cell_h = cell_w
    for col_i = 1, n_cols do
        for row_i = 1, n_rows do
            local cell_x, cell_y = (col_i - 1) * cell_w, (row_i - 1) * cell_h
            table.insert(data, {
                cell_x + 0.5 * cell_w, cell_y + 0.5 * cell_h,
                rt.random.integer(0, self._radius_denominator), -- radius
                rt.random.number(-math.pi, math.pi), -- rotation
                rt.random.number(0, 1), -- hue
            })
        end
    end

    -- radius quantized to uint, so it can be radix sorted

    instance_data_buffer:replace_data(data)
    self._render_shader:send("instance_data_buffer", instance_data_buffer._native)
    self._render_shader:send("radius_denominator", self._radius_denominator)
    self._render_shader:send("max_radius", self._max_radius)
    self._render_shader:send("n_instances", self._n_instances)

    self._update_shader:send("instance_data_buffer", instance_data_buffer._native)
    self._update_shader:send("n_instances", self._n_instances)
    self._update_shader:send("radius_denominator", self._radius_denominator)
    self._update_shader:send("max_radius", self._max_radius)
    self._update_shader:send("screen_size", {love.graphics.getDimensions()})

    self._sort_shader:send("instance_data_buffer", instance_data_buffer._native)
    self._sort_shader:send("instance_data_swap_buffer", instance_data_swap_buffer._native)
    self._sort_shader:send("n_instances", self._n_instances)

    dbg(self._n_instances)
end

--- @override
function rt.Background.OVERLAPPING_DOTS:update(delta)
    self._elapsed = self._elapsed + delta
    self._update_shader:send("elapsed", self._elapsed)
    self._update_shader:dispatch(math.ceil(self._n_instances / 64), 1)
    self._sort_shader:dispatch(1, 1)
end

--- @override
function rt.Background.OVERLAPPING_DOTS:draw()
    love.graphics.setColor(rt.color_unpack(rt.Palette.GRAY_9))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    self._render_shader:bind()
    self._mesh:draw_instanced(self._n_instances)
    self._render_shader:unbind()
end
