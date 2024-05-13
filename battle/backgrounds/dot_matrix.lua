rt.settings.battle.background.dot_matrix = {
    shader_path = "battle/backgrounds/dot_matrix.glsl"
}

bt.Background.DOT_MATRIX = meta.new_type("DOT_MATRIX", bt.Background, function()
    return meta.new(bt.Background.DOT_MATRIX, {
        _shader = {},   -- rt.Shader
        _shape = {},
        _mesh = {},
        _radius = 60,
        _texture = {},
        _elapsed = 0
    })
end)

--- @override
function bt.Background.DOT_MATRIX:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.dot_matrix.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.DOT_MATRIX:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.DOT_MATRIX:update(delta)
    self._elapsed = self._elapsed + delta
end

--- @override
function bt.Background.DOT_MATRIX:draw()
    self._shader:bind()
    self._shader:send("elapsed", self._elapsed)
    --self._shader:send("radius", self._radius)
    self._shape:draw()
    self._shader:unbind()
end
