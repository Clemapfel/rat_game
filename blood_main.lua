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
    local_size = 8
}

local SCREEN_W, SCREEN_H = 1600 / 1.5, 900 / 1.5
local N_PARTICLES = 10000
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

    self._update_particle_cell_id_shader = rt.ComputeShader("blood_update_particle_cell_id.glsl")

    -- init particle buffer

    self._particle_buffer_a = love.graphics.newBuffer(
        self._update_particle_cell_id_shader:get_buffer_format("particle_buffer"),
        self._n_particles,
        buffer_usage
    )

    self._particle_buffer_b = love.graphics.newBuffer(
        self._update_particle_cell_id_shader:get_buffer_format("particle_buffer"),
        self._n_particles,
        buffer_usage
    )

    self._initialize_particle_buffer = function(self)
        local particles = {}
        local x, y, width, height = 0, 0, love.graphics.getDimensions()
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
                cell_i  -- cell_id
            })
        end

        self._particle_buffer_a:setArrayData(particles)
        self._particle_buffer_b:setArrayData(particles) -- for debug only, keep empty
    end
    self:_initialize_particle_buffer()

    -- for each particle, update cell id

    for name_value in range(
        {"particle_buffer", self._particle_buffer_a},
        {"n_particles", self._n_particles},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"cell_width", self._cell_width},
        {"cell_height", self._cell_height}
    ) do
        self._update_particle_cell_id_shader:send(table.unpack(name_value))
    end

    self._update_particle_cell_id = function(self)
        self._update_particle_cell_id_shader:dispatch(1, 1)
    end

    -- split particle range in n groups, for each group, accumulate local counts

    local n_thread_groups = 16
    local n_per_thread_group = math.ceil(self._n_particles / n_thread_groups)
    local n_different_cell_ids = self._n_rows * self._n_columns

    self._sort_local_counts_texture = love.graphics.newCanvas(
        n_different_cell_ids, n_thread_groups, {
            format = rt.TextureFormat.R32UI,
            computewrite = true
        }
    )

    self._sort_accumulate_local_counts_shader = rt.ComputeShader("blood_sort_accumulate_local_counts.glsl")

    for name_value in range(
        {"particle_buffer", self._particle_buffer_a},
        {"local_counts_texture", self._sort_local_counts_texture},
        {"n_particles", self._n_particles}
    ) do
        self._sort_accumulate_local_counts_shader:send(table.unpack(name_value))
    end

    self._sort_accumulate_local_counts = function(self)
        -- reset texture to 0 with draw
        love.graphics.setCanvas(self._sort_local_counts_texture)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setCanvas(nil)

        self._sort_accumulate_local_counts_shader:dispatch(n_thread_groups, 1)
    end

    -- merge local counts

    self._sort_merge_local_counts_shader = rt.ComputeShader("blood_sort_merge_local_counts.glsl")

    self._cell_occupations_buffer = love.graphics.newBuffer(
        self._sort_merge_local_counts_shader:get_buffer_format("cell_occupations_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )

    self._sort_global_counts_buffer = love.graphics.newBuffer(
        self._sort_merge_local_counts_shader:get_buffer_format("global_counts_buffer"),
        n_different_cell_ids,
        buffer_usage
    )

    for name_value in range(
        {"global_counts_buffer", self._sort_global_counts_buffer},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"local_counts_texture", self._sort_local_counts_texture}
    ) do
        self._sort_merge_local_counts_shader:send(table.unpack(name_value))
    end

    local merge_local_counts_dispatch_size = math.ceil(math.sqrt(self._n_rows * self._n_columns))
    self._sort_merge_local_counts = function(self)
        self._sort_merge_local_counts_shader:dispatch(1, 1)
    end

    -- compute prefix sum

    self._sort_compute_prefix_sum_shader = rt.ComputeShader("blood_sort_compute_prefix_sum.glsl", {
    })

    for name_value in range(
        {"global_counts_buffer", self._sort_global_counts_buffer},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns}
    ) do
        self._sort_compute_prefix_sum_shader:send(table.unpack(name_value))
    end

    self._sort_compute_prefix_sum = function(self)
        self._sort_compute_prefix_sum_shader:dispatch(1, 1)
    end

    -- scatter particles

    self._sort_scatter_particles_shader = rt.ComputeShader("blood_sort_scatter_particles.glsl", {
    })

    self._is_sorted_buffer = love.graphics.newBuffer({
        {name = "is_sorted", format = "uint32"}
    }, 1, buffer_usage)

    for name_value in range(
        {"global_counts_buffer", self._sort_global_counts_buffer},
        {"particle_buffer_in", self._particle_buffer_a},
        {"particle_buffer_out", self._particle_buffer_b},
        {"n_rows", self._n_rows},
        {"n_columns", self._n_columns},
        {"n_particles", self._n_particles},
        {"is_sorted_buffer", self._is_sorted_buffer}
    ) do
        self._sort_scatter_particles_shader:send(table.unpack(name_value))
    end

    self._sort_scatter_particles = function(self)
        self._sort_scatter_particles_shader:dispatch(1, 1)
    end

    self._verify_is_sorted = function(self)
        local data = love.graphics.readbackBuffer(self._is_sorted_buffer)
        dbg("is_sorted", data:getUInt32(0))
    end

    -- step

    self._step_simulation_shader = rt.ComputeShader("blood_step_simulation.glsl")

    for name_value in range(
        {"particle_buffer_in", self._particle_buffer_b},
        {"particle_buffer_out", self._particle_buffer_a},
        {"n_particles", self._n_particles},
        {"particle_radius", self._particle_radius},
        {"bounds", {0, 0, love.graphics.getDimensions()}}
    ) do
        self._step_simulation_shader:send(table.unpack(name_value))
    end

    self._step_simulation = function(self, delta)
        self._step_simulation_shader:send("delta", delta)
        self._step_simulation_shader:dispatch(1, 1)
    end

    -- draw spatial hash

    self._debug_draw_spatial_hash_shader = rt.Shader("blood_debug_draw_spatial_hash.glsl")

    for name_value in range(
        {"cell_occupation_buffer", self._cell_occupations_buffer},
        {"n_rows", self._n_rows},
        --{"n_columns", self._n_columns},
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
        --{"n_columns", self._n_columns},
        --{"n_rows", self._n_columns},
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

    self._debug_run_shader = rt.ComputeShader("blood_debug_run.glsl")

    for name_value in range(
        {"particle_buffer_in", self._particle_buffer_a},
        {"particle_buffer_out", self._particle_buffer_b},
        {"cell_occupations_buffer", self._cell_occupations_buffer},
        {"global_counts_buffer", self._sort_global_counts_buffer},
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
    --[[
    self:_update_particle_cell_id()

    self:_sort_accumulate_local_counts()
    self:_sort_merge_local_counts()
    self:_sort_compute_prefix_sum()
    self:_sort_scatter_particles()
    self:_verify_is_sorted()

    self:_step_simulation(delta)
    ]]--

    self:_run_debug(delta)
    self:_verify_is_sorted()
end

--- @override
function rt.FluidSimulation:draw()
    self:_debug_draw_spatial_hash()
    self:_debug_draw_particles()
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