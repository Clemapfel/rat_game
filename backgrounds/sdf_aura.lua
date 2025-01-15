rt.Background.SDF_AURA = meta.new_type("SDF_AURA", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.SDF_AURA, {
        _wall_texture = nil, -- rt.RenderTexture
        
        _left_wall_aabb = nil,
        _right_wall_aabb = nil,
        _top_wall_aabb = nil,
        _bottom_wall_aabb = nil,

        _elapsed = 0,
        _circle_offset = 0,
        _bounds = rt.AABB(0, 0, 1, 1),

        _sdf_texture_a = nil, -- rt.RenderTexture
        _sdf_texture_b = nil,
        _sdf_texture = nil, -- shallow copy of a or b

        _init_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 0 }),
        _compute_sdf_shader = rt.ComputeShader("backgrounds/sdf_aura_compute_sdf.glsl", { MODE = 1 }),
        _render_sdf_shader = rt.Shader("backgrounds/sdf_aura_render_sdf.glsl"),
        _render_wall_shader = rt.Shader("backgrounds/sdf_aura_render_wall.glsl")
    })
end)

--- @override
function rt.Background.SDF_AURA:realize()
    -- noop
end

--- @override
function rt.Background.SDF_AURA:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)

    self._wall_texture = rt.RenderTexture(width, height, 8, rt.TextureFormat.R8, true)

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
    self._elapsed = self._elapsed + delta

    -- draw wall
    self._wall_texture:bind()
    self._render_wall_shader:send("elapsed", self._elapsed)
    love.graphics.clear(0, 0,0, 0)
    for aabb in range(
        self._left_wall_aabb,
        self._right_wall_aabb,
        self._top_wall_aabb,
        self._bottom_wall_aabb
    ) do
        love.graphics.rectangle("fill", rt.aabb_unpack(aabb))
    end
    local width, height = self._bounds.width, self._bounds.height
    love.graphics.circle("fill",
        0.5 * width + math.sin(self._elapsed / 2) * (0.1 * height),
        0.5 * height,
        0.25 * math.min(width, height)
    )
    self._wall_texture:unbind()

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
    self._render_sdf_shader:bind()
    self._sdf_texture:draw()
    self._render_sdf_shader:unbind()

    self._render_wall_shader:bind()
    self._wall_texture:draw(0, 0)
    self._render_wall_shader:unbind()
end
