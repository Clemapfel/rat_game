rt.Background.SDF_AURA = meta.new_type("SDF_AURA", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.SDF_AURA, {
        _metaballs_texture = nil, -- rt.RenderTexture
        
        _left_wall_aabb = nil,
        _right_wall_aabb = nil,
        _top_wall_aabb = nil,
        _bottom_wall_aabb = nil,

        _elapsed = 0,
        _circle_offset = 0,
        _bounds = rt.AABB(0, 0, 1, 1),

        _is_realized = false,
        _particles = {},
        _particle_density = 0.15, -- particles_per_pixel
        _particle_min_radius = 30,
        _particle_max_radius = 50,
        _particle_max_velocity = 10,

        _sdf_texture_a = nil, -- rt.RenderTexture
        _sdf_texture_b = nil,
        _sdf_texture = nil, -- shallow copy of a or b

        _init_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 0 }),
        _compute_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 1 }),
        _render_sdf_shader = rt.Shader("backgrounds/sdf_aura_render_sdf.glsl"),
        _render_wall_shader = rt.Shader("backgrounds/sdf_aura_render_wall.glsl"),
        _render_particle_shader = rt.Shader("backgrounds/sdf_aura_render_particles.glsl"),
        _init_particle_texture_shader = rt.Shader("backgrounds/sdf_aura_init_particle_texture.glsl"),
        _metaballs_threshold = 0.9;
        _jump_flood_threshold = 0.0;

        _step_shader = rt.ComputeShader("backgrounds/sdf_aura_step.glsl"),
        _particle_mesh = nil, -- rt.VertexShape
        _particle_mesh_texture = nil, -- rt.RenderTexture
        _particle_buffer = nil, -- rt.GraphicsBuffer
    })
end)

--- @override
function rt.Background.SDF_AURA:realize()
    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.X then
            self._init_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 0 })
            self._compute_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 1 })
            self._render_sdf_shader = rt.Shader("backgrounds/sdf_aura_render_sdf.glsl")
            self._render_wall_shader = rt.Shader("backgrounds/sdf_aura_render_wall.glsl")
            self._render_particle_shader = rt.Shader("backgrounds/sdf_aura_render_particles.glsl")
            self._init_particle_texture_shader = rt.Shader("backgrounds/sdf_aura_init_particle_texture.glsl")
            self._step_shader = rt.ComputeShader("backgrounds/sdf_aura_step.glsl")

            self:size_allocate(rt.aabb_unpack(self._bounds))
        end
    end)
end

--- @override
function rt.Background.SDF_AURA:size_allocate(x, y, width, height)
    self._n_particles = width * height * self._particle_density / (2 * math.pi * mix(self._particle_min_radius, self._particle_max_radius, 0.5))

    local texture_w = 500
    self._particle_mesh_texture = rt.RenderTexture(texture_w, texture_w)
    self._particle_mesh_texture:bind()
    self._init_particle_texture_shader:bind()
    love.graphics.rectangle("fill", 0, 0, texture_w, texture_w)
    self._init_particle_texture_shader:unbind()
    self._particle_mesh_texture:unbind()

    self._particle_mesh = rt.VertexCircle(0, 0, 1, 1, 32)
    self._particle_mesh:set_texture(self._particle_mesh_texture)

    local padding = 10
    self._bounds = rt.AABB(x, y, width, height)

    -- init particles
    self._particles = {}
    for i = 1, self._n_particles do
        local px, py = rt.random.number() * width, rt.random.number() * height
        local vx, vy = rt.random.number(-1, 1), rt.random.number(-1, 1)
        local radius = rt.random.number(self._particle_min_radius, self._particle_max_radius)
        local as_rgba = rt.lcha_to_rgba(rt.LCHA(0.8, 1, rt.random.number(0, 1)))
        local min_x, max_x = x + padding + radius, x + width - radius - padding
        local min_y, max_y = y + padding + radius, y + height - radius - padding
        table.insert(self._particles, {
            math.min(math.max(px, min_x), max_x),
            math.min(math.max(py, min_y), max_y),
            vx * rt.random.number(0, self._particle_max_velocity),
            vy * rt.random.number(0, self._particle_max_velocity),
            radius,
            rt.random.number(-1, 1),
            as_rgba.r,
            as_rgba.g,
            as_rgba.b
        })
    end

    local buffer_format = {
        { name = "position", format = "floatvec2" },
        { name = "velocity", format = "floatvec2" },
        { name = "radius", format = "float" },
        { name = "radius_velocity", format = "float"},
        { name = "color", format = "floatvec3" },
    }

    self._particle_buffer = rt.GraphicsBuffer(buffer_format, self._n_particles)
    self._particle_buffer:replace_data(self._particles)
    self._step_shader:send("n_particles", self._n_particles)
    self._step_shader:send("particle_buffer", self._particle_buffer._native)
    self._step_shader:send("max_radius", self._particle_max_radius)
    self._step_shader:send("min_radius", self._particle_min_radius)
    self._step_shader:send("bounds", {
        padding, padding, width - 2 * padding, height - 2 * padding
    })

    self._render_particle_shader:send("particle_buffer", self._particle_buffer._native)

    self._render_wall_shader:send("threshold", self._metaballs_threshold)
    self._compute_sdf_shader:send("threshold", self._jump_flood_threshold)

    self._metaballs_texture = rt.RenderTexture(width, height, 8, rt.TextureFormat.RGBA32F, true)
    self._wall_texture = rt.RenderTexture(width, height, 8, rt.TextureFormat.RGBA32F, true)

    local wall_fraction = 0.01
    local normalization_factor = width / height
    local wall_width = wall_fraction * width
    local wall_height = wall_fraction * height * normalization_factor
    local left_x = wall_width
    local right_x = width - wall_width
    local top_y = wall_height
    local bottom_y = height - wall_height
    
    self._left_wall_aabb = rt.AABB(0, 0, wall_width, height)
    self._right_wall_aabb = rt.AABB( right_x, 0, wall_width, height)
    self._top_wall_aabb = rt.AABB(0, 0, width, wall_height)
    self._bottom_wall_aabb = rt.AABB(0, bottom_y, width, wall_height)

    self._sdf_texture_a = rt.RenderTexture(width, height, 0, rt.TextureFormat.RGBA32F, true)
    self._sdf_texture_b = rt.RenderTexture(width, height, 0, rt.TextureFormat.RGBA32F, true)
    self:update(0)
end

--- @override
function rt.Background.SDF_AURA:update(delta)
    if not love.keyboard.isDown("space") then return end
    self._is_realized = true

    self._elapsed = self._elapsed + delta
    self._step_shader:send("delta", delta)
    self._render_sdf_shader:send("elapsed", self._elapsed)

    local dispatch_n = math.ceil(math.sqrt(self._n_particles)) / 8
    self._step_shader:dispatch(dispatch_n, dispatch_n)

    self._metaballs_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendState(
        rt.BlendOperation.ADD,  -- rgb
        rt.BlendOperation.ADD,  -- alpha
        rt.BlendFactor.SOURCE_ALPHA,  -- source rgb
        rt.BlendFactor.ONE, -- source alpha
        rt.BlendFactor.ONE_MINUS_SOURCE_ALPHA, -- dest rgb
        rt.BlendFactor.ONE  -- dest alpha
    )
    self._render_particle_shader:bind()
    self._particle_mesh:draw_instanced(self._n_particles)
    self._render_particle_shader:unbind()
    love.graphics.setBlendMode("alpha")
    self._metaballs_texture:unbind()

    self._wall_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    self._render_wall_shader:bind()
    self._metaballs_texture:draw(0, 0)
    self._render_wall_shader:unbind()
    self._wall_texture:unbind()

    local width, height = self._bounds.width, self._bounds.height

    -- jump flood fill
    self._init_sdf_shader:send("wall_texture", self._wall_texture._native)
    self._init_sdf_shader:send("input_texture", self._sdf_texture_a._native)
    self._init_sdf_shader:send("output_texture", self._sdf_texture_b._native)
    self._init_sdf_shader:dispatch(width / 8, height / 8)

    local jump = 0.5 * math.min(width, height)
    local jump_a_or_b = true
    while jump > 1 do
        if jump_a_or_b then
            self._compute_sdf_shader:send("input_texture", self._sdf_texture_a._native)
            self._compute_sdf_shader:send("output_texture", self._sdf_texture_b._native)
            self._sdf_texture = self._sdf_texture_b
        else
            self._compute_sdf_shader:send("input_texture", self._sdf_texture_b._native)
            self._compute_sdf_shader:send("output_texture", self._sdf_texture_a._native)
            self._sdf_texture = self._sdf_texture_a
        end

        self._compute_sdf_shader:send("jump_distance", jump)
        self._compute_sdf_shader:dispatch(width / 8, height / 8)

        jump_a_or_b = not jump_a_or_b
        jump = jump / 2
    end
end

--- @override
function rt.Background.SDF_AURA:draw()
    if not self._is_realized then return end

    love.graphics.setColor(rt.color_unpack(rt.Palette.WHITE))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    self._render_sdf_shader:bind()
    --self._sdf_texture:draw()
    self._render_sdf_shader:unbind()

    self._metaballs_texture:draw()

    love.graphics.setColor(rt.color_unpack(rt.Palette.BLACK))
    for aabb in range(
        self._left_wall_aabb,
        self._right_wall_aabb,
        self._top_wall_aabb,
        self._bottom_wall_aabb
    ) do
        love.graphics.rectangle("fill", rt.aabb_unpack(aabb))
    end
end
