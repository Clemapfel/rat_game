rt.settings.battle.background.worley = {
    shader_path = "battle/backgrounds/voroworms.glsl"
}

bt.Background.WORLEY = meta.new_type("WORLEY", bt.Background, function()
    return meta.new(bt.Background.WORLEY, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _canvas = rt.RenderTexture(),
        _elapsed = 0
    })
end)

--- @override
function bt.Background.WORLEY:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.worley.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.WORLEY:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    self._canvas = rt.RenderTexture(width, height)
end

--- @override
function bt.Background.WORLEY:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.WORLEY:draw()
    self._shader:bind()
    self._canvas:draw()
    self._shader:unbind()
end
