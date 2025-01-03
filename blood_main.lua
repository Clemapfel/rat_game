require "include"

local particle_buffer_a, particle_buffer_b, cell_memory_mapping_buffer
local particle_buffer_a
local a_or_b = true

local reset_memory_mapping_shader, update_cell_hash_shader
local sort_particles_shader
local step_shader
local render_particle_shader, render_spatial_hash_shader

local particle_mesh
local particle_mesh_n_outer_vertices = 16

local n_particles = 10000
local particle_radius = 5
local particle_mass = 1

local n_particles_per_thread = 1
local window_w, window_h = 800, 600
local x_bounds, y_bounds
local cell_width, cell_height, n_rows, n_columns

local particle_dispatch_size = math.ceil(math.sqrt(n_particles))
local left_wall_aabb, right_wall_aabb, top_wall_aabb, bottom_wall_aabb

love.load = function()
    love.window.setMode(window_w, window_h, {
        vsync = 0,
        msaa = 4
    })

    -- common

    local wall_fraction = 0.01
    local normalization_factor = window_w / window_h
    local wall_width = wall_fraction * window_w
    local wall_height = wall_fraction * window_h * normalization_factor

    local left_x = wall_width
    local right_x = window_w - wall_width
    local top_y = wall_height
    local bottom_y = window_h - wall_height
    x_bounds = {left_x, right_x}
    y_bounds = {top_y, bottom_y}

    left_wall_aabb = rt.AABB(0, 0, wall_width, window_h)
    right_wall_aabb = rt.AABB( right_x, 0, wall_width, window_h)
    top_wall_aabb = rt.AABB(0, 0, window_w, wall_height)
    bottom_wall_aabb = rt.AABB(0, bottom_y, window_w, wall_height)

    cell_width = 4 * particle_radius
    cell_height = cell_width
    n_rows = math.ceil(window_w / cell_width)
    n_columns = math.ceil(window_h / cell_height)


    step_shader = rt.ComputeShader("blood_step.glsl")
    render_particle_shader = rt.Shader("blood_render_particles.glsl")
    render_spatial_hash_shader = rt.Shader("blood_render_spatial_hash.glsl")
    reset_memory_mapping_shader = rt.ComputeShader("blood_reset_memory_mapping.glsl")
    update_cell_hash_shader = rt.ComputeShader("blood_update_cell_hash.glsl", {
        LOCAL_SIZE_X = 32,
        LOCAL_SIZE_Y = 32
    })
    sort_particles_shader = rt.ComputeShader("blood_sort_particles.glsl", {
        N_PARTICLES = n_particles
    })

    particle_buffer_a = rt.GraphicsBuffer(render_particle_shader:get_buffer_format("particle_buffer"), n_particles)
    particle_buffer_b = rt.GraphicsBuffer(render_particle_shader:get_buffer_format("particle_buffer"), n_particles)
    particle_buffer_a = particle_buffer_a

    cell_memory_mapping_buffer = rt.GraphicsBuffer(render_spatial_hash_shader:get_buffer_format("cell_memory_mapping_buffer"), n_rows * n_columns)

    -- render
    do
        local step = (2 * math.pi) / particle_mesh_n_outer_vertices
        local x, y, radius = 0, 0, 1
        local vertices = {{x, y}}
        for angle = 0, 2 * math.pi + step, step do
            table.insert(vertices, {
                x + math.cos(angle) * radius,
                y + math.sin(angle) * radius,
            })
        end

        local vertex_map = {}
        for i = 2, particle_mesh_n_outer_vertices - 1 do
            for j in range(1, i, i + 1) do
                table.insert(vertex_map, j)
            end
        end

        for j in range(1, particle_mesh_n_outer_vertices, 2) do
            table.insert(vertex_map, j)
        end

        particle_mesh = rt.VertexShape(vertices, rt.MeshDrawMode.TRIANGLES, {
            {name = "VertexPosition", format = "floatvec2"},
        })
        particle_mesh._native:setVertexMap(vertex_map)
    end

    render_particle_shader:send("particle_buffer", particle_buffer_a._native)
    render_particle_shader:send("n_particles", n_particles)
    render_particle_shader:send("particle_radius", particle_radius)

    render_spatial_hash_shader:send("cell_memory_mapping_buffer", cell_memory_mapping_buffer._native)
    render_spatial_hash_shader:send("n_columns", n_columns)
    render_spatial_hash_shader:send("n_rows", n_rows)
    render_spatial_hash_shader:send("cell_width", cell_width)
    render_spatial_hash_shader:send("cell_height", cell_height)

    -- init buffers
    do
        function position_to_cell_xy(x, y)
            local cell_x = math.floor(x / cell_width)
            local cell_y = math.floor(y / cell_height)

            return cell_x, cell_y
        end

        function cell_xy_to_cell_i(cell_x, cell_y)
            return cell_y * n_rows + cell_x
        end

        function cell_xy_to_cell_hash(x, y)
            return bit.bor(bit.lshift(x, 16), bit.lshift(y, 0))
        end

        local particle_data = {}
        local cell_memory_mapping_data = {}
        for i = 1, n_rows * n_columns do
            for x in range(0, 0, 0) do
                table.insert(cell_memory_mapping_data, x)
            end
        end

        local min_x, max_x = left_x + particle_radius, right_x - particle_radius
        local min_y, max_y = top_y + particle_radius, bottom_y - particle_radius
        local max_velocity = 50
        for i = 1, n_particles do
            local x = rt.random.number(min_x, max_x)
            local y = rt.random.number(min_y, max_y)
            local cell_x, cell_y = position_to_cell_xy(x, y)

            local vx = rt.random.number(-max_velocity, max_velocity)
            local vy = rt.random.number(-max_velocity, max_velocity)

            for to_insert in range(
                x, y,   -- position
                vx, vy,   -- velocity
                cell_xy_to_cell_hash(cell_x, cell_y)
            ) do
                table.insert(particle_data, to_insert)
            end

            local cell_i = cell_xy_to_cell_i(cell_x, cell_y) * 3 + 1
            local current = cell_memory_mapping_data[cell_i]
            if current == nil then current = 0 end
            cell_memory_mapping_data[cell_i] = current + 1
        end

        particle_buffer_a:replace_data(particle_data)
        particle_buffer_b:replace_data(particle_data)
        cell_memory_mapping_buffer:replace_data(cell_memory_mapping_data)
    end

    -- bind sim uniforms

    reset_memory_mapping_shader:send("cell_memory_mapping_buffer", cell_memory_mapping_buffer._native)
    reset_memory_mapping_shader:send("n_columns", n_columns)
    reset_memory_mapping_shader:send("n_rows", n_rows)

    update_cell_hash_shader:send("particle_buffer", particle_buffer_a._native)
    update_cell_hash_shader:send("cell_memory_mapping_buffer", cell_memory_mapping_buffer._native)
    update_cell_hash_shader:send("n_particles", n_particles)
    update_cell_hash_shader:send("particle_radius", particle_radius)
    update_cell_hash_shader:send("n_columns", n_columns)
    update_cell_hash_shader:send("n_rows", n_rows)
    update_cell_hash_shader:send("cell_width", cell_width)
    update_cell_hash_shader:send("cell_height", cell_height)

    sort_particles_shader:send("particle_buffer_a", particle_buffer_a._native)
    sort_particles_shader:send("particle_buffer_b", particle_buffer_b._native)

    step_shader:send("particle_buffer", particle_buffer_a._native)
    step_shader:send("cell_memory_mapping_buffer", cell_memory_mapping_buffer._native)
    step_shader:send("n_particles", n_particles)
    step_shader:send("particle_radius", particle_radius)
    step_shader:send("x_bounds", x_bounds)
    step_shader:send("y_bounds", y_bounds)
end

love.update = function(delta)
    if a_or_b then
        reset_memory_mapping_shader:send("particle_buffer", particle_buffer_a._native)
        update_cell_hash_shader:send("particle_buffer", particle_buffer_a._native)
        sort_particles_shader:send("particle_buffer_a", particle_buffer_a._native)
        sort_particles_shader:send("particle_buffer_b", particle_buffer_b._native)
    else
        reset_memory_mapping_shader:send("particle_buffer", particle_buffer_b._native)
        update_cell_hash_shader:send("particle_buffer", particle_buffer_b._native)
        sort_particles_shader:send("particle_buffer_a", particle_buffer_b._native)
        sort_particles_shader:send("particle_buffer_b", particle_buffer_a._native)
    end
    
    reset_memory_mapping_shader:dispatch(n_rows, n_columns)
    update_cell_hash_shader:dispatch(1, 1)
    
    sort_particles_shader:dispatch(1, 1)

    if a_or_b then
        step_shader:send("particle_buffer", particle_buffer_b._native)
    else
        step_shader:send("particle_buffer", particle_buffer_a._native)
    end

    step_shader:send("delta", delta)
    step_shader:dispatch(particle_dispatch_size, particle_dispatch_size)

    a_or_b = not a_or_b
end

love.keypressed = function(which)
    if which == "b" then
        love.load()
    end
end

love.draw = function(which)
    -- draw walls
    local value = 0.4
    love.graphics.setColor(value, value, value, 1)
    for aabb in range(
        left_wall_aabb,
        right_wall_aabb,
        top_wall_aabb,
        bottom_wall_aabb
    ) do
        love.graphics.rectangle("fill", rt.aabb_unpack(aabb))
    end

    -- draw spatial hash
    render_spatial_hash_shader:bind()
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    render_spatial_hash_shader:unbind()

    -- draw grid
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    for row_i = 0, n_rows - 1 do
        love.graphics.line(
            row_i / n_rows * window_w, 0,
            row_i / n_rows * window_w, window_h
        )
    end

    for col_i = 0, n_columns - 1 do
        love.graphics.line(
            0, col_i / n_columns * window_h,
            window_w, col_i / n_columns * window_h
        )
    end

    -- draw particles
    render_particle_shader:bind()
    particle_mesh:draw_instanced(n_particles)
    render_particle_shader:unbind()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(n_particles .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end