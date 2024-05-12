rt.settings.battle.background.triangle_tiling = {
    shader_path = "battle/backgrounds/triangle_tiling.glsl"
}

bt.Background.TRIANGLE_TILING = meta.new_type("TRIANGLE_TILING", bt.Background, function()
    return meta.new(bt.Background.TRIANGLE_TILING, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _elapsed = 0
    })
end)

--- @override
function bt.Background.TRIANGLE_TILING:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.triangle_tiling.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.TRIANGLE_TILING:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.TRIANGLE_TILING:update(delta)
    self._elapsed = self._elapsed + delta
    --self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.TRIANGLE_TILING:draw()
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
end

