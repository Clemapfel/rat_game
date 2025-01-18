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
    particle_radius = 5,
    local_size = 8,
    density_radius = 2, -- factor
}

local SCREEN_W, SCREEN_H = 1600 / 1.5, 900 / 1.5
local N_PARTICLES = 1000
local VSYNC = 1

--- @class rt.FluidSimulation
rt.FluidSimulation = meta.new_type("FluidSimulation", function(area_w, area_h, n_particles)
    return meta.new(rt.FluidSimulation, {
        _area_w = area_w,
        _area_h = area_h,
        _n_particles = n_particles,
        _particle_radius = rt.settings.fluid_simulation.particle_radius,

        _n_rows = 0,
        _n_columns = 0,
        _cell_width = 0,
    })
end)

--- @brief
function rt.FluidSimulation:realize()
    local particle_radius = rt.settings.fluid_simulation.particle_radius
    self._cell_width = 4 * particle_radius
    self._cell_height = self._cell_width
    self._n_rows = math.ceil(self._area_w / self._cell_width)
    self._n_columns = math.ceil(self._area_h / self._cell_height)

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
            local cell_i = 0 --cell_y * self._n_rows + cell_x
            table.insert(particles, {
                px, py, -- position
                vx, vy, -- velocity
                cell_i,  -- cell_id,
                0,
                0
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

    self._sort_global_counts_buffer = love.graphics.newBuffer(
        self._debug_run_shader:get_buffer_format("global_counts_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    self._is_sorted_buffer = love.graphics.newBuffer({
        {name = "is_sorted", format = "uint32"}
    }, 1, buffer_usage)

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

    local factor = rt.settings.fluid_simulation.density_radius
    self._density_kernel_mesh = rt.VertexRectangle(
        -1 * factor * self._particle_radius,
        -1 * factor * self._particle_radius,
        2 * factor * self._particle_radius,
        2 * factor * self._particle_radius
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

    -- draw spatial hash

    self._debug_draw_spatial_hash_shader = rt.Shader("blood_debug_draw_spatial_hash.glsl")

    for name_value in range(
        {"cell_occupation_buffer", self._cell_occupations_buffer},
        {"n_rows", self._n_rows},
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
        {"particle_radius", self._particle_radius}
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
        {"density_texture", self._density_texture},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        {"bounds", {0, 0, love.graphics.getDimensions()}},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height},
        {"is_sorted_buffer", self._is_sorted_buffer}
    ) do
        self._debug_run_shader:send(table.unpack(name_value))
    end

    self._run_debug = function(self, delta)
        self._debug_run_shader:send("delta", delta)
        self._debug_run_shader:dispatch(1, 1)
    end
end

--- @override
function rt.FluidSimulation:update(delta)

    self:_run_debug(delta)
    self:_update_density_texture()

    local data = love.graphics.readbackBuffer(self._is_sorted_buffer)
    dbg("is_sorted", data:getUInt32(0))
end

--- @override
function rt.FluidSimulation:draw()
    self:_debug_draw_spatial_hash()
    self:_debug_draw_particles()

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
    if allow_update or love.keyboard.isDown("space") then
        sim:update(delta)
        allow_update = false
    end
end

love.keypressed = function(which)
    if which == "b" then
        allow_update = true
    elseif which == "x" then
        sim:realize()
        allow_update = true
    end
end

love.draw = function()
    sim:draw()

    -- show fps
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(sim._n_particles .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end