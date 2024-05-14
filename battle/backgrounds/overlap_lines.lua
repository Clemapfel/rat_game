bt.Background.OVERLAP_LINES = meta.new_type("OVERLAP_LINES", bt.Background, function()
    return meta.new(bt.Background.OVERLAP_LINES, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _canvas = {},   -- rt.RenderTexture
        _emitters = {},  -- love.ParticleEmitter
        _elapsed = 0
    })
end)

--- @override
function bt.Background.OVERLAP_LINES:realize()
    if self._is_realized == true then return end
    self._is_realized = true
   
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._canvas = rt.RenderTexture()

    local size = 16
    self._particle = rt.RenderTexture(size, size, 0)
    rt.graphics.push()
    rt.graphics.origin()
    self._particle:bind_as_render_target()
    love.graphics.circle("fill", size / 2, size / 2, size / 2)
    self._particle:unbind_as_render_target()

    for i =

    self._emitter = love.graphics.newParticleSystem(self._particle._native, 16)
    self._emitter:setLinearAcceleration(100, 500)
    self._emitter:setParticleLifetime(0.2, 2)
    self._emitter:setSpread(50)

    --[[
    -- fade out
    local n_steps = 5
    local colors = {}
    for i in range(1, n_steps) do
        table.insert(colors, 1)
        table.insert(colors, 1)
        table.insert(colors, 1)
        table.insert(colors, 1)
    end
    table.insert(colors, 1)
    table.insert(colors, 1)
    table.insert(colors, 1)
    table.insert(colors, 0)
    self._emitter:setColors(table.unpack(colors))
    ]]--

end

--- @override
function bt.Background.OVERLAP_LINES:size_allocate(x, y, width, height)
    self._canvas = rt.RenderTexture(width, height, 8)
    self._shape:set_texture(self._canvas)

    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    self._emitter:setEmissionArea("uniform", 0.5 * width, 0.5 * height)
    self._emitter:setColors(1, 1, 1, 1, 0, 0, 0, 1)
end

--- @override
function bt.Background.OVERLAP_LINES:update(delta)
    self._elapsed = self._elapsed + delta

    self._emitter:emit(1)

    self._canvas:bind_as_render_target()
    -- do not clear
    local n_steps = 30
    for i in range(1, n_steps) do
        self._emitter:update(delta / n_steps)
        love.graphics.draw(self._emitter, self._bounds.width / 2, self._bounds.height / 2)
    end
    self._canvas:unbind_as_render_target()
end

--- @override
function bt.Background.OVERLAP_LINES:draw()
    self._shape:draw()
end