--- @class
bt.Animation.KILL = meta.new_type("KILL", rt.Animation, function(scene, target)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(target, bt.EnemySprite)

    return meta.new(bt.Animation.KILL, {
        _step_shader = rt.ComputeShader("battle/animations/kill_step.glsl"),
        _render_shader = rt.Shader("battle/animations/kill_render.glsl"),
        _initialize_shader = rt.ComputeShader("battle/animations/kill_initialize.glsl"),

        _pixel_shape = rt.VertexRectangle(0, 0, 1, 1),
        _pixel_size = rt.settings.sprite.scale_factor,
        _n_instances = 1,

        _scene = scene,
        _target = target,
        _target_w = 0,
        _target_h = 0,

        _color_texture = nil,       -- love.Canvas
        _position_texture = nil,    -- love.Canvas
        _mass_texture = nil,

        _elapsed = 0
    })
end)

--- @brief [internal]
function bt.Animation.KILL:_dispatch(shader)
    shader:dispatch(self._target_w / self._pixel_size, self._target_h / self._pixel_size)
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
    self._target_w = snapshot:get_width()
    self._target_h = snapshot:get_height()
    self._n_instances = self._target_w * self._target_h

    self._color_texture = love.graphics.newCanvas(self._target_w, self._target_h, {
        computewrite = true,
        format = "rgba8"
    }) -- vec4: color rgba

    self._position_texture = love.graphics.newCanvas(self._target_w, self._target_h, {
        computewrite = true,
        format = "rgba32f"
    }) -- vec2: current position (xy) | vec2: previous position (zw)

    self._mass_texture = love.graphics.newCanvas(self._target_w, self._target_h, {
        computewrite = true,
        format = "r8"
    }) -- vec1: mass (read-only)

    -- initialize textures
    local target_x, target_y = self._target:get_position()
    self._initialize_shader:send("aabb", {target_x, target_y, self._target_w, self._target_h})
    self._initialize_shader:send("snapshot", snapshot._native)
    self._initialize_shader:send("snapshot_size", {self._target_w, self._target_h})
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
    self._render_shader:send("snapshot_size", {self._target_w, self._target_h})
    love.graphics.drawInstanced(self._pixel_shape._native, self._n_instances)
    self._render_shader:unbind()
end

--- @override
function bt.Animation.KILL:update(delta)
    self._elapsed = self._elapsed + delta

    self._step_shader:send("position_texture", self._position_texture)
    self._step_shader:send("mass_texture", self._mass_texture)
    self._step_shader:send("color_texture", self._color_texture)
    self._step_shader:send("screen_size", {self._scene._bounds.width, self._scene._bounds.height})
    self._step_shader:send("delta", delta)
    self:_dispatch(self._step_shader)

    return rt.AnimationResult.CONTINUE
end