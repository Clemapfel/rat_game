--[[
use consecutive indices for cell id

split particle range into m where m = number of threadgroups

parallel: accumulate local counts

linear: merge local counts into global counts

parallel: blelloch scan for prefix sum

linear: scatter, construct memory mapping
]]--

rt.settings.fluid_simulation = {
    particle_radius = 5
}

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

        _particle_buffer = nil, -- love.GraphicsBuffer
        _cell_memory_mapping_buffer = nil, -- love.GraphicsBuffer

        -- sorting


        _step_shader = nil, -- love.ComputeShader

    })
end)

--- @brief
function rt.FluidSimulation:realize()

    self._step_shader = love.graphics.newComputeShader("blood_step_simulation.glsl")

    local particle_radius = rt.settings.fluid_simulation.particle_radius
    self._cell_width = 4 * particle_radius
    self._n_rows = math.ceil(self._area_w / self._cell_width)
    self._n_columns = math.ceil(self._area_h / self._cell_width)

    local buffer_usage = {
        shaderstorage = true,
        usage = "static"
    }

    self._particle_buffer = love.graphics.newGraphicsBuffer(
        self._step_shader:getBufferFormat("particle_buffer"),
        self._n_particles,
        buffer_usage
    )

    self._cell_memory_mapping_buffer = love.graphics.newGraphicsBuffer(
        self._step_shader:getBufferFormat("cell_memory_mapping_buffer"),
        self._n_rows * self._n_columns,
        buffer_usage
    )
end


local screen_w, screen_h = 1600 / 1.5, 900 / 1.5
local sim = nil
love.load = function()
    love.window.setMode(screen_w, screen_h, {
        vsync = rt.VSyncMode.ON
    })

    sim = rt.FluidSimulation(screen_w, screen_h)
    sim:realize()
end

love.update = function()
    sim:update()
end

love.draw = function()

end