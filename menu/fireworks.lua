rt.settings.menu.fireworks = {
   particle_texture_w = 1000,
   n_particles_per_group = 800,
   particle_perturbation = 0.024,
   step_size = 1 / 120
}

--- @class mn.Fireworks
--- @param ... Table<Number, Number, Number, Number>
mn.Fireworks = meta.new_type("Fireworks", rt.Widget, function(...)
    local n_args = select("#", ...)
    for i = 1, n_args do
        meta.assert_table(select(i, ...))
    end
    return meta.new(mn.Fireworks, {
        _groups = {...}
    })
end)

local _render_shader = nil
local _step_shader = nil

function mn.Fireworks:realize()
    if _render_shader == nil then _render_shader = rt.Shader("menu/fireworks_render.glsl") end
    if _step_shader == nil then _step_shader = rt.ComputeShader("menu/fireworks_step.glsl") end

    self._render_shader = _render_shader
    self._step_shader = _step_shader

    self._particle_mesh = rt.VertexCircle(0, 0, self._particle_radius)
    local particle_texture_w = rt.settings.menu.fireworks.particle_texture_w
    self._particle_mesh_texture = rt.RenderTexture(particle_texture_w, particle_texture_w, rt.TextureFormat.R32F)
    self._particle_texture_shader = rt.Shader("menu/object_get_fireworks_particle_texture.glsl")

    love.graphics.push()
    love.graphics.origin()
    self._particle_mesh_texture:bind()
    self._particle_texture_shader:bind()
    love.graphics.rectangle("fill", 0, 0, particle_texture_w, particle_texture_w)
    self._particle_texture_shader:unbind()
    self._particle_mesh_texture:unbind()
    love.graphics.pop()
    self._particle_mesh:set_texture(self._particle_mesh_texture)
end

local _MODE_ASCEND = 0
local _MODE_EXPLODE = 1

function mn.Fireworks:size_allocate(x, y, width, height)
    local n_particles_per_group = rt.settings.menu.fireworks.n_particles_per_group
    local n_groups = sizeof(self._groups)
    local n_particles = n_particles_per_group * n_groups

    self._n_groups = n_groups
    self._n_particles_per_group = n_particles_per_group
    self._n_particles = n_particles
    self._dispatch_size = math.ceil(math.sqrt(n_particles) / 32)

    local particle_buffer_format = self._step_shader:get_buffer_format("particle_buffer")
    self._particle_buffer = rt.GraphicsBuffer(particle_buffer_format, n_particles)

    local group_buffer_format = self._step_shader:get_buffer_format("group_buffer")
    self._group_buffer = rt.GraphicsBuffer(group_buffer_format, n_groups)

    local fade_out_buffer_format = self._step_shader:get_buffer_format("fade_out_buffer")
    self._fade_out_buffer = rt.GraphicsBuffer(fade_out_buffer_format, 1)

    local perturbation = rt.settings.menu.fireworks.particle_perturbation
    do
        local particle_data = {}
        local group_data = {}
        for group_i = 1, self.n_groups do
            local start_x, start_y, end_x, end_y = table.unpack(self._groups[group_i])
            table.insert(group_data, {
                start_x, start_y,
                end_x, end_y,
                _MODE_ASCEND
            })

            for particle_i = 1, self.n_particles_per_group do
                local index = particle_i - 1 + 0.5
                local phi = math.acos(1 - 2 * index / self.n_particles_per_group)
                local theta = math.pi * (1 + math.sqrt(5)) * index

                phi = phi + rt.random.number(-perturbation * math.pi, perturbation * math.pi)
                theta = theta + rt.random.number(-perturbation * math.pi, perturbation * math.pi)

                local vx = math.cos(theta) * math.sin(phi)
                local vy = math.sin(theta) * math.sin(phi)
                local vz = math.cos(phi)

                table.insert(particle_data, {
                    start_x, start_y, 0, -- position
                    vx, vy, vz, -- direction
                    0, 0, 0, -- velocity
                    rt.random.number(0, 1), -- hue
                    1, -- value
                    1, -- mass
                    group_i - 1
                })
            end
        end

        self._particle_buffer:replace_data(particle_data)
        self._group_buffer:replace_data(group_data)
    end

    self.texture = rt.RenderTexture(width, height, rt.TextureFormat.RGBA32F)
end

local so_far = 0
function mn.Fireworks:update(delta)
    self._elapsed = self._elapsed + delta

    so_far = so_far + delta
    local step = rt.settings.menu.fireworks.step_size

    for name_value in range(
        {"particle_buffer", self._particle_buffer},
        {"group_buffer", self._group_buffer},
        {"n_groups", self._n_groups},
        {"n_particles_per_group", self._n_particles_per_group},
        {"elapsed", self._elapsed},
        {"delta", step}
    ) do
        self._step_shader:send(table.unpack(name_value))
    end

    self._render_shader:send("particle_buffer", self._particle_buffer)
    local dim_color = rt.settings.menu.fireworks.dim_velocity * step
    while so_far > step do
        self._step_shader:dispatch(self._dispatch_size, self._dispatch_size)

        self._texture:bind()

        love.graphics.setBlendMode("subtract")
        love.graphics.setColor(dim_color, dim_color, dim_color, 1)
        love.graphics.rectangle("fill", 0, 0, self.texture:get_size())
        love.graphics.setBlendMode("alpha")

        self._render_shader:bind()
        love.graphics.setColor(1, 1, 1, 1)
        self._particle_mesh:draw_instanced(self._n_particles)
        self._render_shader:unbind()

        self._texture:unbind()
        so_far = so_far - step
    end
end

function mn.Fireworks:draw()
    self._texture:draw(self._bounds.x, self._bounds.y)
end