--- @class
bt.Animation.DISSOLVE = meta.new_type("DISSOLVE", rt.Animation, function(target)
    return meta.new(bt.Animation.DISSOLVE, {
        _step_shader = rt.ComputeShader("battle/animations/dissolve_compute.glsl"),
        _render_shader = rt.Shader("battle/animations/dissolve_render.glsl"),
        _initialize_shader = rt.ComputeShader("battle/animations/dissolve_initialize.glsl"),
        _pixel_shape = rt.VertexRectangle(0, 0, 1, 1),
        _pixel_size = 4,

        _target = target,
        _target_snapshot = rt.RenderTexture(1, 1),
        _color_texture = nil,
        _position_texture = nil,

        _elapsed = 0
    })
end)

--- @brief
function bt.Animation.DISSOLVE:start()
    local pixel_size = self._pixel_size
    self._pixel_shape:reformat(
        0, 0,
        0, pixel_size,
        pixel_size, pixel_size,
        pixel_size, 0
    )

    local target_w, target_h = self._target:measure()
    self._target_snapshot = rt.RenderTexture(target_w, target_h)
    self._n_instances = math.floor((target_w * target_h) / pixel_size )
    self._target_w = target_w
    self._target_h = target_h

    self._color_texture = love.graphics.newCanvas(target_w, target_h, {
        computewrite = true,
        format = "rgba8"
    }) -- vec4: color rgba


    self._position_texture = love.graphics.newImage(target_w, target_h, {
        computewrite = true,
        format = "rgba16f"
    }) -- vec2: current position (xy) | vec2: current velocity (zw)

    -- initialize from snapshot
    local bounds = self._target:get_bounds()
    love.graphics.push()
    self._target_snapshot:bind()
    love.graphics.translate(-bounds.x, -bounds.y)
    self._target:draw()
    self._target_snapshot:unbind()
    love.graphics.pop()
    --love.graphics.setCanvas()

    self._initialize_shader:send("aabb", {bounds.x, bounds.y, bounds.width, bounds.height})
    self._initialize_shader:send("snapshot", self._target_snapshot._native)
    self._initialize_shader:send("snapshot_size", {target_w, target_h})
    self._initialize_shader:send("position_texture", self._position_texture)
    self._initialize_shader:send("color_texture", self._color_texture)
    self._initialize_shader:send("pixel_size", self._pixel_size)
    self._initialize_shader:dispatch(self._target_w / pixel_size, self._target_h / pixel_size)

    self._render_shader:send("position_texture", self._position_texture)
    self._render_shader:send("color_texture", self._color_texture)
    self._render_shader:send("snapshot_size", {target_w, target_h})
    self._render_shader:send("red", {rt.color_unpack(rt.Palette.RED)})

    self._step_shader:send("position_texture", self._position_texture)
end

--- @brief
function bt.Animation.DISSOLVE:update(delta)
    self._elapsed = self._elapsed + delta
    self._render_shader:send("elapsed", self._elapsed)

    self._step_shader:send("delta", delta)
    --self._step_shader:send("screen_size", {love.graphics.getDimensions()})
    --self._step_shader:send("floor_y", love.graphics.getHeight() * 0.9)
    self._step_shader:dispatch(self._target_w / self._pixel_size, self._target_h / self._pixel_size)

    return rt.AnimationResult.CONTINUE
end

--- @brief
function bt.Animation.DISSOLVE:draw()
    self._render_shader:bind()
    love.graphics.drawInstanced(self._pixel_shape._native, self._n_instances)
    self._render_shader:unbind()

    --love.graphics.draw(self._color_texture, 50, 50)
end