
bt.Background.CLOUDS = meta.new_type("CLOUDS", bt.Background, function()
    return meta.new(bt.Background.CLOUDS, {
        _path = "battle/backgrounds/clouds.glsl",
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _canvas = rt.RenderTexture(),
        _elapsed = rt.random.number(-2^16, 2^16)
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

    self._canvas = rt.RenderTexture(width, height)
end

--- @override
function bt.Background.CLOUDS:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.CLOUDS:draw()
    self._shader:bind()
    self._canvas:draw()
    self._shader:unbind()
end
