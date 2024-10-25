--- @class
bt.Animation.KILL = meta.new_type("KILL", rt.Animation, function(scene, target)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(target, bt.EnemySprite)

    return meta.new(bt.Animation.KILL, {
        _step_shader = rt.ComputeShader("battle/animations/kill_step.glsl"),
        _render_shader = rt.Shader("battle/animations/kill_render.glsl"),
        _initialize_shader = rt.ComputeShader("battle/animations/kill_initialize.glsl"),

        _pixel_shape = rt.VertexRectangle(0, 0, 1, 1),
        _pixel_size = 4, --rt.settings.sprite.scale_factor,
        _n_instances = 1,

        _scene = scene,
        _target = target,
        _target_aabb = rt.AABB(0, 0, 1, 1),

        _color_texture = nil,       -- love.Canvas
        _position_texture = nil,    -- love.Canvas
        _mass_texture = nil,        -- love.Canvas
        _n_done_counter = nil,      -- love.GraphicsBuffer



        _elapsed = 0
    })
end)

--- @brief [internal]
function bt.Animation.KILL:_dispatch(shader)
    shader:dispatch(
        self._target_aabb.width / self._pixel_size,
        self._target_aabb.height / self._pixel_size
    )
end

--- @brief
function bt.Animation.KILL:start()
    local pixel_size = self._pixel_size
    self._pixel_shape:reformat(
        0, 0,
        0, pixel_size,
        pixel_size, pixel_size,
        pixel_size, 0
    )

    local snapshot = self._target:get_snapshot()
    self._target_aabb.width = snapshot:get_width()
    self._target_aabb.height = snapshot:get_height()
    self._target_aabb.x, self._target_aabb.y = self._target:get_position()
    self._n_instances = (self._target_aabb.width * self._target_aabb.height) / self._pixel_size

    local texture_w, texture_h = self._target_aabb.width / self._pixel_size, self._target_aabb.height / self._pixel_size
    self._color_texture = love.graphics.newCanvas(texture_w, texture_h, {
        computewrite = true,
        format = "rgba16f"
    }) -- vec4: color rgba

    self._position_texture = love.graphics.newCanvas(texture_w, texture_h, {
        computewrite = true,
        format = "rgba32f"
    }) -- vec2: current position (xy) | vec2: previous position (zw)

    self._mass_texture = love.graphics.newCanvas(texture_w, texture_h, {
        computewrite = true,
        format = "r8"
    }) -- vec1: mass (read-only)

    self._n_done_counter = love.graphics.newBuffer('uint32', 1, {
        usage = "dynamic",
        shaderstorage = true
    }) -- struct { uint n[1]; }

    -- initialize textures
    local target_x, target_y = self._target:get_position()
    self._target_aabb = rt.AABB(target_x, target_y, self._target_aabb.width, self._target_aabb.height)
    self._initialize_shader:send("aabb", {target_x, target_y, self._target_aabb.width, self._target_aabb.height})
    self._initialize_shader:send("snapshot", snapshot._native)
    self._initialize_shader:send("snapshot_size", {self._target_aabb.width, self._target_aabb.height})
    self._initialize_shader:send("pixel_size", self._pixel_size)

    self._initialize_shader:send("position_texture", self._position_texture)
    self._initialize_shader:send("color_texture", self._color_texture)
    self._initialize_shader:send("mass_texture", self._mass_texture)
    self:_dispatch(self._initialize_shader)

    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.KILL:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.KILL:draw(delta)
    self._render_shader:bind()
    self._render_shader:send("position_texture", self._position_texture)
    self._render_shader:send("color_texture", self._color_texture)
    self._render_shader:send("snapshot_size", {self._target_aabb.width, self._target_aabb.height})
    love.graphics.drawInstanced(self._pixel_shape._native, self._n_instances)
    self._render_shader:unbind()

    love.graphics.draw(self._mass_texture, 0, 0)
    love.graphics.draw(self._color_texture, 0, self._mass_texture:getHeight())
end

--- @override
function bt.Animation.KILL:update(delta)
    --delta = clamp(delta, 0, 1 / 60)
    self._elapsed = self._elapsed + delta

    local center_x, center_y = love.mouse.getPosition()

    self._step_shader:send("position_texture", self._position_texture)
    self._step_shader:send("mass_texture", self._mass_texture)
    self._step_shader:send("color_texture", self._color_texture)
    self._step_shader:send("n_done_counter", self._n_done_counter)
    
    self._step_shader:send("delta", delta)
    self._step_shader:send("elapsed", self._elapsed)
    self._step_shader:send("screen_aabb", {rt.aabb_unpack(self._scene:get_bounds())})
    self._step_shader:send("dispatch_size", {self._target_aabb.width / self._pixel_size, self._target_aabb.height / self._pixel_size})
    self._step_shader:send("center_of_gravity", {
        self._target_aabb.x + 0.5 * self._target_aabb.width,
        self._target_aabb.y + 0.5 * self._target_aabb.height
    })
    self:_dispatch(self._step_shader)

    local readback = love.graphics.readbackBuffer(self._n_done_counter)
    local n_done = ffi.cast("uint32_t*", readback:getFFIPointer())[0]
    if n_done >= (self._n_instances / 2) then -- TODO: why / 2 ?
        return rt.AnimationResult.DISCONTINUE
    else
        return rt.AnimationResult.CONTINUE
    end
end