rt.settings.menu.fireworks = {
   particle_texture_w = 200,
   n_particles_per_group = 800,
   step_size = 1 / 120,
   particle_radius = 3.5,
   dim_velocity = 3
}

--- @class mn.Fireworks
mn.Fireworks = meta.class("Fireworks", rt.Widget)

--- @param ... Table<Number, Number, Number, Number>
function mn.Fireworks:instantiate(...)
    local n_args = select("#", ...)
    for i = 1, n_args do
        meta.assert_table(select(i, ...))
    end

    meta.install(self, {
        _groups = {...},
        _elapsed = 0,
        _started = false
    })
end

local _init_shader = nil
local _render_shader = nil
local _step_shader = nil

function mn.Fireworks:realize()
    if self:already_realized() then return end

    if _init_shader == nil then _init_shader = rt.ComputeShader("menu/fireworks_init.glsl") end
    if _render_shader == nil then _render_shader = rt.Shader("menu/fireworks_render.glsl") end
    if _step_shader == nil then _step_shader = rt.ComputeShader("menu/fireworks_step.glsl") end

    self._render_shader = _render_shader
    self._step_shader = _step_shader

    self._particle_radius = rt.settings.menu.fireworks.particle_radius
    self._particle_mesh = rt.VertexCircle(0, 0, self._particle_radius)
    local particle_texture_w = rt.settings.menu.fireworks.particle_texture_w
    self._particle_mesh_texture = rt.RenderTexture(particle_texture_w, particle_texture_w, rt.TextureFormat.R32F)
    self._particle_texture_shader = rt.Shader("menu/fireworks_particle_texture.glsl")

    love.graphics.push()
    love.graphics.origin()
    self._particle_mesh_texture:bind()
    self._particle_texture_shader:bind()
    love.graphics.rectangle("fill", 0, 0, particle_texture_w, particle_texture_w)
    self._particle_texture_shader:unbind()
    self._particle_mesh_texture:unbind()
    love.graphics.pop()
    self._particle_mesh:set_texture(self._particle_mesh_texture)
    self._particle_mesh:set_color(1, 1, 1, 1)
end

local _MODE_ASCEND = 0
local _MODE_EXPLODE = 1
local once = true

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

    self._reset = function(self)
        do -- init group buffer
            local group_data = {}
            for group_i = 1, self._n_groups do
                local start_x, start_y, end_x, end_y = table.unpack(self._groups[group_i])
                table.insert(group_data, {
                    start_x, start_y, 0,
                    end_x, end_y, 0
                })
            end
            self._group_buffer:replace_data(group_data)
        end

        _init_shader:send("particle_buffer", self._particle_buffer)
        _init_shader:send("group_buffer", self._group_buffer)
        _init_shader:send("n_groups", self._n_groups)
        _init_shader:send("n_particles_per_group", self._n_particles_per_group)
        _init_shader:dispatch(self._dispatch_size, self._dispatch_size)
    end
    self:_reset()
    self._texture = rt.RenderTexture(width, height, rt.TextureFormat.RGBA32F)
end

local so_far = 0
function mn.Fireworks:update(delta)
    if self._is_started ~= true then return end
    self._elapsed = self._elapsed + delta

    so_far = so_far + delta
    local step = rt.settings.menu.fireworks.step_size

    for name_value in range(
        {"particle_buffer", self._particle_buffer},
        {"group_buffer", self._group_buffer},
        {"n_groups", self._n_groups},
        {"n_particles_per_group", self._n_particles_per_group},
        {"particle_radius", self._particle_radius},
        {"elapsed", self._elapsed},
        {"delta", step}
    ) do
        self._step_shader:send(table.unpack(name_value))
    end

    self._render_shader:send("particle_buffer", self._particle_buffer)
    local dim_color = rt.settings.menu.fireworks.dim_velocity * step
    while so_far >= step do
        self._step_shader:dispatch(self._dispatch_size, self._dispatch_size)
        self._texture:bind()

        rt.graphics.set_blend_mode(rt.BlendMode.SUBTRACT, rt.BlendMode.SUBTRACT)
        love.graphics.setColor(dim_color, dim_color, dim_color, dim_color)
        love.graphics.rectangle("fill", 0, 0, self._texture:get_size())
        love.graphics.setBlendMode("alpha")

        self._render_shader:bind()
        self._particle_mesh:draw_instanced(self._n_particles)
        self._render_shader:unbind()

        self._texture:unbind()
        so_far = so_far - step
    end
end

function mn.Fireworks:draw()
    love.graphics.setColor(1, 1, 1, 1)
    self._texture:draw(self._bounds.x, self._bounds.y)
end

function mn.Fireworks:start()
    dbg("called")
    if self._is_started == true then self:_reset() end
    self._elapsed = 0
    self._is_started = true
end