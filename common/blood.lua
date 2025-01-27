rt.settings.fluid_simulation = {
    particle_radius = 11.5,
    density_kernel_resolution = 50
}

--- @class rt.FluidSimulation
rt.FluidSimulation = meta.new_type("FluidSimulation", function(area_w, area_h, n_particles)
    local radius = rt.settings.fluid_simulation.particle_radius
    return meta.new(rt.FluidSimulation, {
        _area_w = area_w,
        _area_h = area_h,
        _cell_width = 0,
        _cell_height = 0,
        _n_columns = 1,
        _n_rows = 1,
        _particle_radius = radius,
        _near_radius = 0.5 * radius,

        _construct_particle_occupations_shader = nil, -- rt.ComputeShader
        _density_compute_derivative_shader = nil,
        _update_particle_density_shader = nil,
        _step_shader = nil,
        _sdf_preprocess_hitbox_shader = nil,
        _sdf_init_shader = nil,
        _sdf_step_shader = nil,
        _sdf_compute_gradient_shader = nil,
        _apply_local_force_shader = nil,

        _density_kernel_init_shader = nil, -- rt.Shader
        _density_kernel_draw_shader = nil,
        _draw_density_shader = nil,

        _particle_buffer_a = nil, -- love.GraphicsBuffer
        _particle_buffer_b = nil,
        _cell_occupations_buffer = nil,
        _sort_global_counts_buffer = nil,
        _is_sorted_buffer = nil,

        _density_kernel_texture = nil, -- love.Canvas
        _density_texture = nil,
        _hitbox_texture_a = nil,
        _hitbox_texture_b = nil,
        _sdf_texture_a = nil,
        _sdf_texture_b = nil,

        _density_kernel_mesh = nil, -- rt.VertexShape
        _step_dispatch_size = 1
    })
end)

--- @brief
function rt.FluidSimulation:realize()
    local particle_radius = self._particle_radius
    self._cell_width = 4 * particle_radius
    self._cell_height = self._cell_width
    self._n_columns = math.ceil(self._area_w / self._cell_width)
    self._n_rows = math.ceil(self._area_h / self._cell_height)

    self._step_dispatch_size = math.ceil(math.sqrt(self._n_particles) / 32)

    -- shaders

    self._construct_particle_occupations_shader = rt.ComputeShader("common/blood_construct_particle_occupations.glsl")
    self._density_kernel_init_shader = rt.Shader("common/blood_density_kernel_init.glsl")
    self._density_kernel_draw_shader = rt.Shader("common/blood_density_kernel_draw.glsl")
    self._density_compute_derivative_shader = rt.ComputeShader("common/blood_density_compute_derivative.glsl")
    self._draw_density_shader = rt.Shader("common/blood_draw_density.glsl")
    self._update_particle_density_shader = rt.ComputeShader("common/blood_update_particle_density.glsl")
    self._step_shader = rt.ComputeShader("common/blood_step.glsl")

    self._sdf_preprocess_hitbox_shader = rt.ComputeShader("common/blood_preprocess_hitbox.glsl")
    self._sdf_init_shader = rt.ComputeShader("common/blood_compute_sdf.glsl", {MODE = 0})
    self._sdf_step_shader = rt.ComputeShader("common/blood_compute_sdf.glsl", {MODE = 1})
    self._sdf_compute_gradient_shader = rt.ComputeShader("common/blood_compute_sdf.glsl", {MODE = 2})

    self._apply_local_force_shader = rt.ComputeShader("common/blood_apply_local_forces.glsl")

    -- buffers

    local buffer_usage = {
        shaderstorage = true,
        usage = "static"
    }

    self._particle_buffer_a = love.graphics.newBuffer(
        self._construct_particle_occupations_shader:get_buffer_format("particle_buffer_a"),
        self._n_particles,
        buffer_usage
    )

    self._particle_buffer_b = love.graphics.newBuffer(
        self._construct_particle_occupations_shader:get_buffer_format("particle_buffer_b"),
        self._n_particles,
        buffer_usage
    )

    self:_initialize_particle_buffer()

    self._cell_occupations_buffer = love.graphics.newBuffer(
        self._construct_particle_occupations_shader:get_buffer_format("cell_occupations_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    self._sort_global_counts_buffer = love.graphics.newBuffer(
        self._construct_particle_occupations_shader:get_buffer_format("global_counts_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    self._is_sorted_buffer = love.graphics.newBuffer({
        {name = "is_sorted", format = "uint32"}
    }, 1, buffer_usage)

    local density_kernel_resolution = rt.settings.fluid_simulation.density_kernel_resolution
    self._density_kernel_texture = love.graphics.newCanvas(density_kernel_resolution, density_kernel_resolution, {
        format = rt.TextureFormat.R32F,
        computewrite = true
    }) -- r: density

    self:_init_density_kernel()

    local radius = self._particle_radius
    self._density_kernel_mesh = rt.VertexRectangle(
        -1 * radius,
        -1 * radius,
        2 * radius,
        2 * radius
    )
    self._density_kernel_mesh._native:setTexture(self._density_kernel_texture)

    local density_texture_config = {
        format = rt.TextureFormat.RGBA32F,
        computewrite = true
    } -- r: density, gb: directional derivative

    self._density_texture = love.graphics.newCanvas(self._area_w, self._area_h, density_texture_config)

    local hitbox_texture_config = {
        format = rt.TextureFormat.R8,
        computewrite = true,
        msaa = 4
    } -- r: is wall

    self._hitbox_texture_a = love.graphics.newCanvas(self._area_w, self._area_h, hitbox_texture_config)
    self._hitbox_texture_b = love.graphics.newCanvas(self._area_w, self._area_h, hitbox_texture_config)

    local sdf_texture_config = {
        format = rt.TextureFormat.RGBA32F,
        computewrite = true
    } -- xy: nearest true wall pixel, z: distance

    self._sdf_texture_a = love.graphics.newCanvas(self._area_w, self._area_h, sdf_texture_config)
    self._sdf_texture_b = love.graphics.newCanvas(self._area_w, self._area_h, sdf_texture_config)

    -- bind uniforms

    self._density_kernel_draw_shader:send("particle_buffer", self._particle_buffer_a)
    self._density_compute_derivative_shader:send("density_texture", self._density_texture)

    self._draw_density_shader:send("red", {self._color.r, self._color.g, self._color.b})
    self._draw_density_shader:send("hitbox_texture", self._hitbox_texture_a)

    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"global_counts_buffer", self._sort_global_counts_buffer},
        {"n_particles", self._n_particles},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height},
        {"is_sorted_buffer", self._is_sorted_buffer}
    ) do
        self._construct_particle_occupations_shader:send(table.unpack(name_value))
    end

    for name_value in range(
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        {"near_radius", self._near_radius},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height}
    ) do
        self._update_particle_density_shader:send(table.unpack(name_value))
    end

    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"particle_radius", self._particle_radius},
        {"near_radius", self._near_radius},
        {"n_particles", self._n_particles},
        {"bounds", {0, 0, love.graphics.getDimensions()}},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height},
        {"delta", self._sim_delta}
    ) do
        self._step_shader:send(table.unpack(name_value))
    end

    for name_value in range(
        {"input_texture", self._hitbox_texture_a},
        {"output_texture", self._hitbox_texture_b},
        {"particle_radius", self._particle_radius}
    ) do
        self._sdf_preprocess_hitbox_shader:send(table.unpack(name_value))
    end

    for name_value in range(
        {"input_texture", self._sdf_texture_a},
        {"output_texture", self._sdf_texture_b}
    ) do
        self._sdf_init_shader:send(table.unpack(name_value))
        self._sdf_step_shader:send(table.unpack(name_value))
    end
    self._sdf_init_shader:send("hitbox_texture", self._hitbox_texture_b)

    for name_value in range(
        {"particle_buffer_b", self._particle_buffer_b},
        {"n_particles", self._n_particles},
        {"delta", self._sim_delta}
    ) do
        self._apply_local_force_shader:send(table.unpack(name_value))
    end
end

--- @override
function rt.FluidSimulation:update(delta)
    self:_update_density_texture()
    self:_update_hitbox_texture()
    self:_update_sdf_texture()

    self:_construct_particle_occupations()

    if love.mouse.isDown(1) then
        self:_apply_local_force(love.mouse.getPosition())
    end

    self:_update_particle_density()
    self:_step(delta)

    local data = love.graphics.readbackBuffer(self._is_sorted_buffer)
    assert(data:getUInt32(0))
end

--- @override
function rt.FluidSimulation:draw()
    --self:_debug_draw_spatial_hash()
    --self:_debug_draw_particles()

    self._draw_density_shader:bind()
    love.graphics.draw(self._density_texture)
    self._draw_density_shader:unbind()
end

--- @brief
function rt.FluidSimulation:_initialize_particle_buffer()
    local particles = {}
    local x, y, width, height = 0, 0, self._area_w, self._area_h
    local radius = self._particle_radius
    local padding = 10
    local max_velocity = 10
    for i = 1, self._n_particles do
        local vx, vy = rt.random.number(-1, 1) * max_velocity, rt.random.number(-1, 1) * max_velocity
        local min_x, max_x = x + padding + radius, x + width - radius - padding
        local min_y, max_y = y + padding + radius, y + height - radius - padding
        local px = math.min(math.max(rt.random.number() * width, min_x), max_x)
        local py = math.min(math.max(rt.random.number() * height, min_y), max_y)

        local cell_x = math.floor(px / self._cell_width)
        local cell_y = math.floor(px / self._cell_height)
        local cell_i = cell_y * self._n_rows + cell_x
        table.insert(particles, {
            px, py, -- position
            0, 0, --vx, vy, -- velocity
            0, -- density
            0, -- near_density
            cell_i,  -- cell_id
        })
    end

    self._particle_buffer_a:setArrayData(particles)
    self._particle_buffer_b:setArrayData(particles) -- for debug only, keep empty
end

function rt.FluidSimulation:_init_density_kernel()
    local density_kernel_resolution = rt.settings.fluid_simulation.density_kernel_resolution
    love.graphics.setCanvas(self._density_kernel_texture)
    love.graphics.setShader(self._density_kernel_init_shader._native)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.rectangle("fill", 0, 0, density_kernel_resolution, density_kernel_resolution)
    love.graphics.pop()
    love.graphics.setShader(nil)
    love.graphics.setCanvas(nil)
end

function rt.FluidSimulation:_update_density_texture()
    love.graphics.setBlendMode("add")
    love.graphics.setCanvas(self._density_texture)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(self._density_kernel_draw_shader._native)
    self._density_kernel_mesh:draw_instanced(self._n_particles)
    love.graphics.setShader()
    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha")

    self._density_compute_derivative_shader:dispatch(self._area_w / 32, self._area_h / 32)
end

function rt.FluidSimulation:_construct_particle_occupations()
    self._construct_particle_occupations_shader:dispatch(1, 1)
end

function rt.FluidSimulation:_update_particle_density()
    self._update_particle_density_shader:dispatch(self._step_dispatch_size, self._step_dispatch_size)
end

local _elapsed = 0
function rt.FluidSimulation:_step(delta)
    delta = 1 / 60
    _elapsed = _elapsed + delta
    local sim_delta = self._sim_delta
    while _elapsed > sim_delta do
        self._step_shader:dispatch(self._step_dispatch_size, self._step_dispatch_size)
        _elapsed = _elapsed - sim_delta
    end
end

function rt.FluidSimulation:_update_sdf_texture()
    local dispatch_size_x, dispatch_size_y = math.ceil(self._area_w) / 32 + 1, math.ceil(self._area_h) / 32 + 1

    -- jump flood fill
    self._sdf_init_shader:dispatch(dispatch_size_x, dispatch_size_y)

    local jump = 0.5 * math.min(self._area_w, self._area_h)
    local jump_a_or_b = true
    while jump >= 1 do -- JFA+1
        if jump_a_or_b then
            self._sdf_step_shader:send("input_texture", self._sdf_texture_a)
            self._sdf_step_shader:send("output_texture", self._sdf_texture_b)
        else
            self._sdf_step_shader:send("input_texture", self._sdf_texture_b)
            self._sdf_step_shader:send("output_texture", self._sdf_texture_a)
        end

        self._sdf_step_shader:send("jump_distance", math.ceil(jump))
        self._sdf_step_shader:dispatch(dispatch_size_x, dispatch_size_y)

        jump_a_or_b = not jump_a_or_b
        jump = jump / 2
    end

    if jump_a_or_b then
        self._sdf_compute_gradient_shader:send("input_texture", self._sdf_texture_a)
        self._sdf_compute_gradient_shader:send("output_texture", self._sdf_texture_b)
        self._step_shader:send("sdf_texture", self._sdf_texture_b)
    else
        self._sdf_compute_gradient_shader:send("input_texture", self._sdf_texture_b)
        self._sdf_compute_gradient_shader:send("output_texture", self._sdf_texture_a)
        self._step_shader:send("sdf_texture", self._sdf_texture_a)
    end

    self._sdf_compute_gradient_shader:dispatch(dispatch_size_x, dispatch_size_y)
end

function rt.FluidSimulation:_update_hitbox_texture()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas({self._hitbox_texture_a, stencil = true})
    love.graphics.clear(0, 0, 0, 0)
    local wall_fraction = 0.02
    local wall_w = math.max(wall_fraction * self._area_w, wall_fraction * self._area_h)
    local w, h = self._area_w, self._area_h
    local stencil_value = 128
    rt.graphics.stencil(stencil_value, function()
        love.graphics.rectangle("fill",
            wall_w,
            wall_w,
            w - 2 * wall_w,
            h - 2 * wall_w,
            50
        )
    end)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL)
    love.graphics.rectangle("fill", 0, 0, w, h)
    rt.graphics.set_stencil_test(nil)

    local clock = rt.InterpolationFunctions.SINE_WAVE(self._elapsed, 0.2)
    local pillar_w, pillar_h = 0.1 * w, clock * 0.5 * h
    local pillar_x, pillar_y = 0.5 * w - 0.5 * pillar_w, h - pillar_h
    love.graphics.rectangle("fill", pillar_x, pillar_y, pillar_w, pillar_h)

    love.graphics.circle("fill",
        pillar_x + 0.5 * pillar_w,
        pillar_y,
        0.5 * pillar_w,
        0.5 * pillar_w
    )

    local platform_w, platform_h = 0.4 * w, 0.01 * h
    love.graphics.rectangle("fill",
        pillar_x + 0.5 * pillar_w - 0.5 * platform_w,
        pillar_y,
        platform_w, platform_h
    )

    local cage_w, cage_h = 0.2 * w, 0.25 * h
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line",
        0.5 * w - 0.5 * cage_w,
        wall_w,
        cage_w, cage_h
    )

    love.graphics.setCanvas(nil)
    self._sdf_preprocess_hitbox_shader:dispatch(
        math.ceil(self._area_w) / 32 + 1,
        math.ceil(self._area_h) / 32 + 1
    )
end

function rt.FluidSimulation:_apply_local_force(x, y)
    self._apply_local_force_shader:send("center", {x, y})
    self._apply_local_force_shader:send("force_direction", 1)
    self._apply_local_force_shader:dispatch(self._step_dispatch_size, self._step_dispatch_size)
end
