--[[
use consecutive indices for cell id

split particle range into m where m = number of threadgroups

parallel: accumulate local counts

linear: merge local counts into global counts

parallel: blelloch scan for prefix sum

linear: scatter, construct memory mapping
]]--

require "include"

rt.settings.fluid_simulation = {
    particle_radius = 12,
}

local screen_size_div = 3
local SCREEN_W, SCREEN_H = 1600 / screen_size_div, 900 / screen_size_div
local n_particles = 5000
local VSYNC = 1

--- @class rt.FluidSimulation
rt.FluidSimulation = meta.new_type("FluidSimulation", function(area_w, area_h)
    local radius = rt.settings.fluid_simulation.particle_radius
    return meta.new(rt.FluidSimulation, {
        _area_w = area_w,
        _area_h = area_h,
        _n_particles = n_particles,
        _particle_radius = radius,
        _particle_mass = 1,
        _n_rows = 0,
        _n_columns = 0,
        _cell_width = 0,
        _sim_delta = 1 / (60 * 2)
    })
end)

--- @brief
function rt.FluidSimulation:realize()
    local particle_radius = rt.settings.fluid_simulation.particle_radius
    self._cell_width = 4 * particle_radius
    self._cell_height = self._cell_width
    self._n_columns = math.ceil(self._area_w / self._cell_width)
    self._n_rows = math.ceil(self._area_h / self._cell_height)

    local local_size = rt.settings.fluid_simulation.local_size
    self._particle_dispatch_size = math.ceil(math.sqrt(self._n_particles))

    local buffer_usage = {
        shaderstorage = true,
        usage = "static"
    }

    self._debug_run_shader = rt.ComputeShader("blood_debug_run.glsl")

    -- buffers

    self._particle_buffer_a = love.graphics.newBuffer(
        self._debug_run_shader:get_buffer_format("particle_buffer_a"),
        self._n_particles,
        buffer_usage
    )

    self._particle_buffer_b = love.graphics.newBuffer(
        self._debug_run_shader:get_buffer_format("particle_buffer_b"),
        self._n_particles,
        buffer_usage
    )

    self._initialize_particle_buffer = function(self)
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
    self:_initialize_particle_buffer()

    self._cell_occupations_buffer = love.graphics.newBuffer(
        self._debug_run_shader:get_buffer_format("cell_occupations_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    do
        local data = {}
        for i = 1, self._n_rows * self._n_columns do
            table.insert(data, {0, 0})
        end

        self._cell_occupations_buffer:setArrayData(data)
    end

    self._sort_global_counts_buffer = love.graphics.newBuffer(
        self._debug_run_shader:get_buffer_format("global_counts_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    self._is_sorted_buffer = love.graphics.newBuffer({
        {name = "is_sorted", format = "uint32"}
    }, 1, buffer_usage)

    local step_dispatch_size = math.ceil(math.sqrt(self._n_particles) / 16)

    -- density kernel

    local density_kernel_resolution = 50
    self._density_kernel_texture = love.graphics.newCanvas(density_kernel_resolution, density_kernel_resolution, {
        format = rt.TextureFormat.R32F,
        computewrite = true
    }) -- r: density

    self._density_kernel_init_shader = rt.Shader("blood_density_kernel_init.glsl")

    love.graphics.setCanvas(self._density_kernel_texture)
    love.graphics.setShader(self._density_kernel_init_shader._native)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.rectangle("fill", 0, 0, density_kernel_resolution, density_kernel_resolution)
    love.graphics.pop()
    love.graphics.setShader(nil)
    love.graphics.setCanvas(nil)

    local radius = self._particle_radius
    self._density_kernel_mesh = rt.VertexRectangle(
        -1 * radius,
        -1 * radius,
        2 * radius,
        2 * radius
    )
    self._density_kernel_mesh._native:setTexture(self._density_kernel_texture)

    -- density

    self._density_texture = love.graphics.newCanvas(self._area_w, self._area_h, {
        format = rt.TextureFormat.RGBA32F,
        computewrite = true
    }) -- r: density, gb: directional derivative

    self._density_kernel_draw_shader = rt.Shader("blood_density_kernel_draw.glsl")
    self._density_kernel_draw_shader:send("particle_buffer", self._particle_buffer_a)

    self._density_compute_derivative_shader = rt.ComputeShader("blood_density_compute_derivative.glsl")
    self._density_compute_derivative_shader:send("density_texture", self._density_texture)
    self._density_texture_w = self._area_w
    self._density_texture_h = self._area_h

    self._update_density_texture = function(self)
        love.graphics.setBlendMode("add")
        love.graphics.setCanvas(self._density_texture)
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setShader(self._density_kernel_draw_shader._native)
        self._density_kernel_mesh:draw_instanced(self._n_particles)
        love.graphics.setShader()
        love.graphics.setCanvas()
        love.graphics.setBlendMode("alpha")

        self._density_compute_derivative_shader:dispatch(self._density_texture_w, self._density_texture_h)
    end

    self._debug_draw_density_shader = rt.Shader("blood_debug_draw_density.glsl")
    local red = rt.Palette.RED_4 --rt.Palette.CINNABAR_4
    self._debug_draw_density_shader:send("red", {red.r, red.g, red.b})

    -- draw spatial hash

    self._debug_draw_spatial_hash_shader = rt.Shader("blood_debug_draw_spatial_hash.glsl")

    for name_value in range(
        {"cell_occupation_buffer", self._cell_occupations_buffer},
        --{"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height}
    ) do
        self._debug_draw_spatial_hash_shader:send(table.unpack(name_value))
    end

    self._fullscreen_mesh = rt.VertexRectangle(0, 0, love.graphics.getDimensions())
    self._debug_draw_spatial_hash = function(self)
        self._debug_draw_spatial_hash_shader:bind()
        self._fullscreen_mesh:draw()
        self._debug_draw_spatial_hash_shader:unbind()
    end

    -- draw particles

    self._debug_draw_particles_shader = rt.Shader("blood_debug_draw_particles.glsl")

    for name_value in range(
        {"particle_buffer", self._particle_buffer_a},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns}
    ) do
        self._debug_draw_particles_shader:send(table.unpack(name_value))
    end
    
    self._particle_mesh = rt.VertexCircle(0, 0, 1, 1, 32)
    self._debug_draw_particles = function(self)  
        self._debug_draw_particles_shader:bind()
        self._particle_mesh:draw_instanced(self._n_particles)
        self._debug_draw_particles_shader:unbind()
    end

    -- debug

    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"global_counts_buffer", self._sort_global_counts_buffer},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height},
        {"is_sorted_buffer", self._is_sorted_buffer}
    ) do
        self._debug_run_shader:send(table.unpack(name_value))
    end

    self._run_debug = function(self, delta)
        self._debug_run_shader:dispatch(1, 1)
    end

    -- update density

    self._near_radius = 0.3 * particle_radius

    self._update_particle_density_shader = rt.ComputeShader("blood_update_particle_density.glsl")
    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"delta", self._sim_delta},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        --{"particle_mass", self._particle_mass},
        {"near_radius", self._near_radius},
        {"bounds", {0, 0, love.graphics.getDimensions()}},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height}
    ) do
        self._update_particle_density_shader:send(table.unpack(name_value))
    end

    self._update_particle_density = function(self)
        self._update_particle_density_shader:dispatch(step_dispatch_size, step_dispatch_size)
    end

    -- step

    self._step_shader = rt.ComputeShader("blood_step.glsl")
    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"particle_radius", self._particle_radius},
        {"near_radius", self._near_radius},
        {"n_particles", self._n_particles},
        --{"particle_mass", self._particle_mass},
        {"bounds", {0, 0, love.graphics.getDimensions()}},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height},
        {"delta", self._sim_delta}

    ) do
        self._step_shader:send(table.unpack(name_value))
    end

    local elapsed = 0
    self._step = function(self, delta)
        elapsed = elapsed + delta
        local sim_delta = self._sim_delta
        while elapsed > sim_delta do
            self._step_shader:dispatch(step_dispatch_size, step_dispatch_size)
            elapsed = elapsed - sim_delta
        end
    end

    -- pick up
    self._apply_local_force_shader = rt.ComputeShader("blood_apply_local_forces.glsl")

    for name_value in range(
        {"particle_buffer_a", self._particle_buffer_a},
        {"particle_buffer_b", self._particle_buffer_b},
        {"n_particles", self._n_particles},
        {"delta", self._sim_delta}
    ) do
        self._apply_local_force_shader:send(table.unpack(name_value))
    end

    self._apply_local_force = function(self, x, y)
        self._apply_local_force_shader:send("center", {x, y})
        self._apply_local_force_shader:send("force_direction", 1)
        self._apply_local_force_shader:dispatch(step_dispatch_size, step_dispatch_size)
    end
end

--- @override
function rt.FluidSimulation:update(delta)
    self:_update_density_texture()
    self:_run_debug()

    if love.mouse.isDown(1) then
        self:_apply_local_force(love.mouse.getPosition())
    end

    self:_update_particle_density()
    self:_step(delta)

    local data = love.graphics.readbackBuffer(self._is_sorted_buffer)
    dbg("is_sorted", data:getUInt32(0))
end

--- @override
function rt.FluidSimulation:draw()
    --self:_debug_draw_spatial_hash()
    --self:_debug_draw_particles()

    self._debug_draw_density_shader:bind()
    love.graphics.draw(self._density_texture)
    self._debug_draw_density_shader:unbind()
end

local sim = nil
love.load = function()
    love.window.setMode(SCREEN_W, SCREEN_H, {
        vsync = VSYNC
    })

    sim = rt.FluidSimulation(SCREEN_W, SCREEN_H, N_PARTICLES)
    sim:realize()
end

allow_update = true
love.update = function(delta)
    --if allow_update or love.keyboard.isDown("space") then
        sim:update(delta)
        allow_update = false
    --end
end

love.keypressed = function(which)
    if which == "b" then
        allow_update = true
    elseif which == "x" then
        sim:realize()
        sim:update(1 / 60)
        allow_update = true
    end
end

love.draw = function()
    sim:draw()

    -- show fps
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(sim._n_particles .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end