rt.settings.backgrounds.guitar_strings = {
    shader_path = "battle/backgrounds/guitar_strings.glsl"
}

bt.Background.GUITAR_STRINGS = meta.new_type("GUITAR_STRINGS", bt.Background, function()
    return meta.new(bt.Background.GUITAR_STRINGS, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _elapsed = rt.random.number(-2^16, 2^16)
    })
end)

--- @override
function bt.Background.GUITAR_STRINGS:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.backgrounds.guitar_strings.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.GUITAR_STRINGS:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.GUITAR_STRINGS:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.GUITAR_STRINGS:draw()
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
end
