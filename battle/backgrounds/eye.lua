rt.settings.battle.background.eye = {
    shader_path = "battle/backgrounds/eye.glsl"
}

bt.Background.EYE = meta.new_type("EYE", bt.Background, function()
    return meta.new(bt.Background.EYE, {
        _shader = {},   -- rt.Shader
        _shape = {},
        _texture = {},
        _elapsed = 0,
        _hue = rt.rgba_to_hsva(rt.Palette.RED_3).h,
        _black = rt.Palette.BLACK,
        _last_intensity = 0,
        _current_intensity = 0,
        _stimulus = 0
    })
end)

--- @override
function bt.Background.EYE:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.eye.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.EYE:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.EYE:update(delta, intensity)
    self._elapsed = self._elapsed + delta

    self._last_intensity = self._current_intensity
    self._current_intensity = intensity
    self._stimulus = self._stimulus - delta * (3 - math.abs(self._stimulus, 3))
    self._stimulus = self._stimulus + clamp(self._current_intensity - self._last_intensity, 0)
end

--- @override
function bt.Background.EYE:draw()
    self._shader:bind()
    self._shader:send("elapsed", self._elapsed)
    self._shader:send("hue", self._hue)
    self._shader:send("gamma", clamp(self._stimulus, 1))
    self._shape:draw()
    self._shader:unbind()
end
