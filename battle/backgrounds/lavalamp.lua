rt.settings.battle.background.lavalamp = {
    shader_path = "battle/backgrounds/lavalamp.glsl"
}

bt.Background.LAVALAMP = meta.new_type("LAVALAMP", bt.Background, function()
    return meta.new(bt.Background.LAVALAMP, {
        _shader = rt.Shader(rt.settings.battle.background.lavalamp.shader_path),
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _elapsed = 0
    })
end)

--- @override
function bt.Background.LAVALAMP:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.LAVALAMP:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.LAVALAMP:draw()
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
end

