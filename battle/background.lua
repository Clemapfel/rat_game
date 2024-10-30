rt.settings.battle.background = {
    compression = 1.0
}

--- @class bt.Background
bt.Background = meta.new_abstract_type("BattleBackground", rt.Widget)

--- @override
function bt.Background:update(delta, spectrum)
    -- noop
end

-- ###

bt.ShaderOnlyBackground = meta.new_type("ShaderOnlyBackground", bt.Background, function(path, disabled_elapsed, enable_compression)
    return meta.new(bt.ShaderOnlyBackground, {
        _path = path,
        _shader = {},   -- rt.Shader
        _mask_shape = {}, -- rt.VertexShape
        _shape = {},    -- rt.VertexShape
        _elapsed = rt.random.number(0, 2^8),
        _disable_elapsed = disabled_elapsed,
        _enable_compression = which(enable_compression, false),
        _render_texture = rt.RenderTexture(),
        _position_x = 0,
        _position_y = 0
    })
end)

--- @override
function bt.ShaderOnlyBackground:realize()
    if self:already_realized() then return end
    self._is_realized = true
    self._shader = rt.Shader(self._path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._mask_shape = rt.VertexRectangle(0, 0, 1, 1)

    local contrast = rt.settings.contrast
    for i = 1, 4 do
        self._shape:set_vertex_color(i, rt.RGBA(1, 1, 1, 1))
        self._mask_shape:set_vertex_color(i, rt.RGBA(0, 0, 0, 1 - contrast))
    end
end

--- @override
function bt.ShaderOnlyBackground:size_allocate(x, y, width, height)
    for shape in range(self._shape, self._mask_shape) do
        shape:set_vertex_position(1, x, y)
        shape:set_vertex_position(2, x + width, y)
        shape:set_vertex_position(3, x + width, y + height)
        shape:set_vertex_position(4, x, y + height)
    end

    local factor = rt.settings.battle.background.compression
    self._render_texture = rt.RenderTexture(factor * width, factor * height)
    self._render_texture:set_scale_mode(rt.TextureScaleMode.LINEAR)
    self._shape:set_texture(self._render_texture)

    self._position_x, self._position_y = x, y
end

--- @override
function bt.ShaderOnlyBackground:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta

    if self._shader:has_uniform("elapsed") then
        self._shader:send("elapsed", self._elapsed)
    end

    if self._enable_compression then
        self._shader:send("compression", rt.settings.battle.background.compression)
    end

    local contrast = rt.settings.battle.background.contrast
    for i = 1, 4 do
        self._mask_shape:set_vertex_color(i, rt.RGBA(contrast, contrast, contrast, 1))
    end

    self._render_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()
    self._render_texture:unbind()
end

--- @override
function bt.ShaderOnlyBackground:draw()
    if self._is_realized ~= true then return end

    self._shader:bind()
    self._shape:draw()
    self._shader:unbind()

    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
    self._mask_shape:draw()
    rt.graphics.set_blend_mode()
end

-- include all implementations
for _, name in pairs(love.filesystem.getDirectoryItems("battle/backgrounds")) do
    if string.match(name, "%.lua$") ~= nil then
        local path = "battle.backgrounds." .. string.gsub(name, "%.lua$", "")
        require(path)
    end
end
