--- @class
bt.Animation.DISSOLVE = meta.new_type("DISSOLVE", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.DISSOLVE, {
        _step_shader = rt.ComputeShader("battle/animations/dissolve_compute.glsl"),
        _render_shader = rt.Shader("battle/animations/dissolve_render.glsl"),
        _initialize_shader = rt.ComputeShader("battle/animations/dissolve_initialize.glsl"),
        _pixel_shape = rt.VertexRectangle(0, 0, 1, 1),

        _target = target,
        _target_snapshot = rt.RenderTexture(1, 1),
        _color_texture = nil,
        _position_texture = nil
    })
end)

--- @brief
function bt.Animation.DISSOLVE:realize()
    local pixel_size = 1
    self._pixel_shape:reformat(
        0, 0,
        0, pixel_size,
        pixel_size, pixel_size,
        pixel_size, 0
    )

    local target_w, target_h = self._target:measure()
    self._target_snapshot = rt.RenderTexture(target_w, target_h)._native
    self._n_instances = target_w * target_h

    self._color_texture = love.graphics.newCanvas(self._n_instances, 1, {
        computewrite = true,
        format = "rgba8"
    }) -- vec4: color rgba


    self._position_texture = love.graphics.newImage(self._n_instances, 1, {
        computewrite = true,
        format = "rgba16f"
    }) -- vec2: current position (xy) | vec2: current velocity (zw)

    -- initialize from snapshot
    local bounds = self._target:get_bounds()
    love.graphics.setCanvas(self._target_snapshot)
    love.graphics.push()
    love.graphics.translate(-bounds.x, -bounds.y)
    self._target:draw()
    love.graphics.pop()
    love.graphics.setCanvas()

    dbg(bounds)
    self._initialize_shader:send("aabb", {bounds.x, bounds.y, bounds.width, bounds.height})
    self._initialize_shader:send("snapshot", self._target_snapshot)
    self._initialize_shader:send("snapshot_size", {target_w, target_h})
    self._initialize_shader:send("position_texture", self._position_texture)
    self._initialize_shader:send("color_texture", self._color_texture)
    self._initialize_shader:dispatch(self._n_instances, 1)

    self._render_shader:send("position_texture", self._position_texture)
    self._render_shader:send("color_texture", self._color_texture)

    self._step_shader:send("position_texture", self._position_texture)
    self._step_shader:send("color_texture", self._color_texture)
end

--- @brief
function bt.Animation.DISSOLVE:update(delta)
    self._step_shader:send("delta", delta)
    self._step_shader:dispatch(self._n_instances)
end

--- @brief
function bt.Animation.DISSOLVE:draw()
    self._render_shader:bind()
    love.graphics.drawInstanced(self._pixel_shape._native, self._n_instances)
    self._render_shader:unbind()

    love.graphics.draw(self._color_texture, 50, 50)
end