rt.settings.battle.background.clouds = {
    compression_factor = 2
}

bt.Background.CLOUDS = meta.new_type("CLOUDS", bt.Background, function()
    return meta.new(bt.Background.CLOUDS, {
        _path = "battle/backgrounds/clouds.glsl",
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _canvas = rt.RenderTexture(),
        _elapsed = 0,
    })
end)

--- @override
function bt.Background.CLOUDS:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(self._path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.CLOUDS:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    local factor = rt.settings.battle.background.clouds.compression_factor
    self._canvas = rt.RenderTexture(width / factor, height / factor)
    self._canvas:set_scale_mode(rt.TextureScaleMode.LINEAR)
end

--- @override
function bt.Background.CLOUDS:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)

    self._shape:set_texture(nil)
    self._canvas:bind_as_render_target()
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
    self._canvas:unbind_as_render_target()
    self._shape:set_texture(self._canvas)
end

--- @override
function bt.Background.CLOUDS:draw()
    self._shape:draw()
end
