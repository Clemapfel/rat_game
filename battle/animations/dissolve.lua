--- @class
bt.Animation.DISSOLVE = meta.new_type("DISSOLVE", rt.QueueableAnimation, function(target)
    return meta.new(rt.Animation.DISSOLVE, {
        _compute_shader = rt.ComputeShader("battle/animations/dissolve_compute.glsl"),
        _render_shader = rt.Shader("battle/animations/dissolve_render.glsl"),
        _pixel_shape = rt.VertexShape(0, 0, 1, 1),
        _target = target,
        _target_snapshot = rt.RenderTexture(1, 1),
        _color_texture = nil,
        _position_texture = nil,
        _pixel_size = 2,
        _n_pixels = 1,
    })
end)

--- @brief
function bt.Animation.DISSOLVE:realize()
    local pixel_size = self._pixel_size
    self._pixel_shape:reformat(
        0, 0,
        0, pixel_size,
        pixel_size, pixel_size,
        pixel_size, 0
    )

    local target_w, target_h = self._target:measure()
    self._n_pixels = (target_w * target_h) / pixel_size
    self._color_texture = love.grapics.newCanvas(self._n_pixels, 1, {
        computewrite = false,
        format = "rgba8"
    })

    self._position_texture = love.graphics.newImage(self._n_pixels, 1, {
        computewrite = true,
        format = "rgba16f"
    })

    love.graphics.setCanvas(self._color_texture)
    love.graphics.push()
    love.graphics.reset()
    self._target:draw()
    love.graphics.pop()
    love.graphics.setCanvas()
end

--- @brief
function bt.Animation.DISSOLVE:update(delta)

end

--- @brief
function bt.Animation.DISSOLVE:draw()
    love.graphics.draw(self._color_texture)
end