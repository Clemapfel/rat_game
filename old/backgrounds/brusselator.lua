rt.settings.battle.background.brusselator = {
    shader_path = "battle/backgrounds/brusselator.glsl",
}

bt.Background.BRUSSELATOR = meta.new_type("BRUSSELATOR", bt.Background, function()
    return meta.new(bt.Background.BRUSSELATOR, {
        _texture = {},  -- rt.RenderTexture
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexRectangle
        _elapsed = 0
    })
end)

--- @override
function bt.Background.BRUSSELATOR:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._texture = rt.RenderTexture(1, 1)
    self._shader = rt.Shader(rt.settings.battle.background.brusselator.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.BRUSSELATOR:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    self._texture = rt.RenderTexture(width, height)
    self._shape:set_texture(self._texture)

    self._shader:bind()
    self._shader:send("mode", 0) -- initialize
    self._texture:bind_as_render_target()
    self._shape:draw()
    self._texture:unbind_as_render_target()
    self._shader:unbind()

end

--- @override
function bt.Background.BRUSSELATOR:update(delta, intensity)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta

    self._shader:bind()
    self._shader:send("mode", 1) -- step
    self._texture:bind_as_render_target()
    self._texture:draw()
    self._texture:unbind_as_render_target()
    self._shader:unbind()
end

--- @override
function bt.Background.BRUSSELATOR:draw()
    if self._is_realized ~= true then return end
    self._shader:send("mode", 2) -- draw
    self._shape:draw()
end
