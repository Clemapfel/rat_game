rt.settings.battle.background.lichen = {
    shader_path = "battle/backgrounds/lichen.glsl",
    texture_format = "rg8"
}

bt.Background.ShaderMode = meta.new_enum({
    INITIALIZE = -1,
    DRAW = 0,
    STEP = 1,
})

bt.Background.LICHEN = meta.new_type("LICHEN", bt.Background, function()
    return meta.new(bt.Background.LICHEN, {
        _textures = {},  -- Pair<rt.RenderTexture>
        _texture_order = true,
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexRectangle
        _elapsed = 0,
        _total_elapsed = 0,
    })
end)

--- @override
function bt.Background.LICHEN:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._shader = rt.Shader(rt.settings.battle.background.lichen.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @brief
function bt.Background.LICHEN:_get_texture_from_to()
    if self._texture_order == true then
        return self._textures[1], self._textures[2]
    else
        return self._textures[2], self._textures[1]
    end
end

--- @override
function bt.Background.LICHEN:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    local texture_w, texture_h = width / 2, height / 2
    local format = rt.settings.battle.background.lichen.pixel_format
    self._textures[1] = rt.RenderTexture(texture_w, texture_h, false, format)
    self._textures[2] = rt.RenderTexture(texture_w, texture_h, false, format)

    local from, to = self:_get_texture_from_to()
    for texture in range(from, to) do
        self._shader:bind()
        self._shader:send("mode", bt.Background.ShaderMode.INITIALIZE)
        texture:bind_as_render_target()
        self._shape:draw()
        texture:unbind_as_render_target()
        self._shader:unbind()
    end

    self._shape:set_texture(from)
end

--- @override
function bt.Background.LICHEN:update(delta, intensity)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta
    self._total_elapsed = self._total_elapsed + delta
    local step_duration = 1 / 30
    while (self._elapsed > step_duration) do
        rt.graphics.push()
        rt.graphics.origin()
        local from, to = self:_get_texture_from_to()
        self._shader:bind()
        self._shader:send("mode", bt.Background.ShaderMode.STEP)
        self._shader:send("texture_from", from._native)
        --self._shader:send("delta", delta)
        --self._shader:send("elapsed", self._total_elapsed)
        self._shader:send("texture_size", {from:get_size()})
        to:bind_as_render_target()
        from:draw()
        to:unbind_as_render_target()
        self._shader:unbind()

        --self._shape:set_texture(to)
        self._texture_order = not self._texture_order
        rt.graphics.pop()

        self._elapsed = self._elapsed - step_duration
    end
end

--- @override
function bt.Background.LICHEN:draw()
    if self._is_realized ~= true then return end

    local from, to = self:_get_texture_from_to()
    self._shader:bind()
    self._shader:send("mode", bt.Background.ShaderMode.DRAW)
    self._shader:send("texture_from", from._native)
    self._shape:draw()
    self._shader:unbind()
end
