require "include"

local particle_buffer_a, particle_buffer_b, cell_memory_mapping_buffer
local sdf_texture_a, sdf_texture_b, sdf_texture -- xy: nearest wall coords (abs), z: distance
local wall_texture -- x: is wall
local density_texture -- x: density
local a_or_b = true

local reset_memory_mapping_shader, update_cell_hash_shader
local sort_particles_shader
local step_shader
local render_particle_shader, render_spatial_hash_shader
local init_sdf_shader, compute_sdf_shader, render_sdf_shader

local density_kernel_texture, init_density_kernel_shader, render_density_kernel_shader, render_density_texture_shader
local particle_mesh, density_kernel_mesh
local particle_mesh_n_outer_vertices = 16

local n_particles = 3000
local particle_radius = 5
local particle_density_influence_multiplier = 2
local particle_mass = 1
local pressure_multiplier = 10;

local n_particles_per_thread = 1
local window_w, window_h = 800, 600
local x_bounds, y_bounds
local cell_width, cell_height, n_rows, n_columns

local particle_dispatch_size = math.ceil(math.sqrt(n_particles))
local left_wall_aabb, right_wall_aabb, top_wall_aabb, bottom_wall_aabb

love.load = function()
    love.window.setMode(window_w, window_h, {
        vsync = rt.VSyncMode.ON,
        msaa = 0
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
    render_density_kernel_shader = rt.Shader("blood_render_density_kernel.glsl")
    render_density_texture_shader = rt.Shader("blood_render_density_texture.glsl")
    render_spatial_hash_shader = rt.Shader("blood_render_spatial_hash.glsl")
    reset_memory_mapping_shader = rt.ComputeShader("blood_reset_memory_mapping.glsl")
    update_cell_hash_shader = rt.ComputeShader("blood_update_cell_hash.glsl", {
        LOCAL_SIZE_X = 32,
        LOCAL_SIZE_Y = 32
    })

    sort_particles_shader = rt.ComputeShader("blood_sort_particles.glsl", {
        N_PARTICLES = n_particles
    })

    init_sdf_shader = rt.ComputeShader("blood_compute_sdf.glsl", {
        MODE = 0
    })

    compute_sdf_shader = rt.ComputeShader("blood_compute_sdf.glsl", {
        MODE = 1
    })

    render_sdf_shader = rt.Shader("blood_render_sdf.glsl")

    particle_buffer_a = rt.GraphicsBuffer(render_particle_shader:get_buffer_format("particle_buffer"), n_particles)
    particle_buffer_b = rt.GraphicsBuffer(render_particle_shader:get_buffer_format("particle_buffer"), n_particles)
    particle_buffer_a = particle_buffer_a

    sdf_texture_a = rt.RenderTexture(window_w, window_h, 0, rt.TextureFormat.RGBA32F, true)
    sdf_texture_b = rt.RenderTexture(window_w, window_h, 0, rt.TextureFormat.RGBA32F, true)
    wall_texture = rt.RenderTexture(window_w, window_h, 0, rt.TextureFormat.R8, true)

    density_texture = rt.RenderTexture(window_w, window_h, 0, rt.TextureFormat.R32F, true)
    cell_memory_mapping_buffer = rt.GraphicsBuffer(render_spatial_hash_shader:get_buffer_format("cell_memory_mapping_buffer"), n_rows * n_columns)

    -- init density kernel texture
    density_kernel_texture = rt.RenderTexture(
        2 * particle_radius * particle_density_influence_multiplier,
        2 * particle_radius * particle_density_influence_multiplier,
        0, rt.TextureFormat.R32F, false
    )
    init_density_kernel_shader = rt.Shader("blood_init_density_kernel.glsl")
    density_kernel_texture:bind()
    init_density_kernel_shader:bind()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, density_kernel_texture:get_width(), density_kernel_texture:get_height())
    init_density_kernel_shader:unbind()
    density_kernel_texture:unbind()

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

    local density_w = density_kernel_texture:get_width()
    density_kernel_mesh = rt.VertexRectangle(-density_w, -density_w, 2 * density_w, 2 * density_w)
    density_kernel_mesh:set_texture(density_kernel_texture)

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

        local constrain = 0.0
        local min_x, max_x = left_x + particle_radius + constrain * window_w, right_x - particle_radius - constrain * window_w
        local min_y, max_y = top_y + particle_radius + constrain * window_h, bottom_y - particle_radius - constrain * window_h
        local max_velocity = 50
        for i = 1, n_particles do
            local x = rt.random.number(min_x, max_x)
            local y = rt.random.number(min_y, max_y)
            local cell_x, cell_y = position_to_cell_xy(x, y)

            local vx = rt.random.number(-max_velocity, max_velocity)
            local vy = rt.random.number(-max_velocity, max_velocity)

            for to_insert in range(
                x, y,   -- position
                0, 0,   -- velocity
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

    step_shader:send("n_rows", n_rows)
    step_shader:send("n_columns", n_columns)
    step_shader:send("screen_size", {window_w, window_h})
    --step_shader:send("pressure_multiplier", pressure_multiplier)
    step_shader:send("density_texture", density_texture._native)
    step_shader:send("particle_buffer", particle_buffer_a._native)
    step_shader:send("cell_memory_mapping_buffer", cell_memory_mapping_buffer._native)
    step_shader:send("n_particles", n_particles)
    step_shader:send("particle_radius", particle_radius)
    step_shader:send("x_bounds", x_bounds)
    step_shader:send("y_bounds", y_bounds)
end

love.update = function(delta)
    if love.keyboard.isDown("space") == false then return end

    -- update SDF

    wall_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    for aabb in range(
        left_wall_aabb,
        right_wall_aabb,
        top_wall_aabb,
        bottom_wall_aabb
    ) do
        love.graphics.rectangle("fill", rt.aabb_unpack(aabb))
    end
    love.graphics.circle("fill",0.5 * window_w, 0.5 * window_h, 0.25 * math.min(window_w, window_h))
    wall_texture:unbind()

    init_sdf_shader:send("init_texture", wall_texture._native)
    init_sdf_shader:send("input_texture", sdf_texture_a._native)
    init_sdf_shader:send("output_texture", sdf_texture_b._native)
    init_sdf_shader:dispatch(window_w / 8, window_h / 8)
    sdf_texture = sdf_texture_a

    --[[
    local jump = 0.5 * math.min(window_w, window_h)
    local jump_a_or_b = true
    while jump > 1 do
        if jump_a_or_b then
            compute_sdf_shader:send("input_texture", sdf_texture_a._native)
            compute_sdf_shader:send("output_texture", sdf_texture_b._native)
            sdf_texture = sdf_texture_b
        else
            compute_sdf_shader:send("input_texture", sdf_texture_b._native)
            compute_sdf_shader:send("output_texture", sdf_texture_a._native)
            sdf_texture = sdf_texture_a
        end

        compute_sdf_shader:send("jump_distance", jump)
        compute_sdf_shader:dispatch(window_w / 8, window_h / 8)

        jump_a_or_b = not jump_a_or_b
        jump = jump / 2
    end
    ]]--

    -- update spatial hash
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

    -- update density
    love.graphics.push()
    density_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()
    love.graphics.setBlendMode("add")
    render_density_kernel_shader:bind()
    if a_or_b then
        render_density_kernel_shader:send("particle_buffer", particle_buffer_b._native)
    else
        render_density_kernel_shader:send("particle_buffer", particle_buffer_a._native)
    end
    render_density_kernel_shader:send("wall_texture", wall_texture._native)
    render_density_kernel_shader:send("sdf_texture", sdf_texture._native)
    density_kernel_mesh:draw_instanced(n_particles)
    render_density_kernel_shader:unbind()

    density_texture:unbind()
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()

    -- step simulation
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

    -- draw sdf
    --[[
    love.graphics.setColor(1, 1, 1, 1)
    render_sdf_shader:bind()
    sdf_texture:draw()
    render_sdf_shader:unbind()
    ]]--

    -- draw spatial hash
    render_spatial_hash_shader:bind()
    --love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
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
    if a_or_b then
        render_density_kernel_shader:send("particle_buffer", particle_buffer_b._native)
        render_particle_shader:send("particle_buffer", particle_buffer_b._native)
    else
        render_density_kernel_shader:send("particle_buffer", particle_buffer_a._native)
        render_particle_shader:send("particle_buffer", particle_buffer_a._native)
    end

    render_particle_shader:bind()
    particle_mesh:draw_instanced(n_particles)
    render_particle_shader:unbind()

    love.graphics.setBlendMode("lighten", "premultiplied")
    render_density_texture_shader:bind()
    density_texture:draw()
    render_density_texture_shader:unbind()
    love.graphics.setBlendMode("alpha")

    -- show fps
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(n_particles .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end