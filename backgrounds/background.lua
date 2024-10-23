rt.settings.background = {
    target_frame_fraction = 0.15, -- how much of a frame the background is allowed to take up before automatic compression kicks in
    use_dynamic_resolution = false,
}

--- @class rt.Background
rt.Background = meta.new_type("Background", rt.Widget, rt.Animation, function(implementation_type)
    local out = meta.new(rt.Background, {
        _implementation = nil, -- rt.BackgroundImplementation
        _current_compression = 1,
        _dynamic_resolution_freeze_count = 0,
        _render_texture = rt.RenderTexture(1, 1),
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _mask_shape = rt.VertexRectangle(0, 0, 1, 1),
        _position_x = 0,
        _position_y = 0
    })

    if implementation_type ~= nil then
        out:set_implementation(implementation_type)
    end

    return out
end)

--- @brief
function rt.Background:set_implementation(implementation_type)
    meta.assert_is_subtype(implementation_type, rt.BackgroundImplementation)
    self._implementation = implementation_type()

    if self._is_realized then
        self._implementation:realize()
        self:reformat()
    end
end

--- @brief
function rt.Background:_update_render_texture()
    if self._implementation == nil then return end

    local before = love.timer.getTime()
    self._render_texture:bind()
    love.graphics.clear(true, false, false)
    self._implementation:draw()
    self._render_texture:unbind()
    local after = love.timer.getTime()
    local fraction = (after - before) / (1 / rt.graphics.get_target_fps())
end

--- @overrider
function rt.Background:update(delta, ...)
    if self._is_realized ~= true or self._implementation == nil then return end
    self._implementation:update(delta, ...)
    self:_update_render_texture()

    self._dynamic_resolution_freeze_count = self._dynamic_resolution_freeze_count + 1
    if rt.settings.background.use_dynamic_resolution and self._dynamic_resolution_freeze_count > 120 then
        local before = self._current_compression
        local step = 0.025

        if rt.graphics.get_fps() < 0.98 * rt.graphics.get_target_fps() then
            self._current_compression = self._current_compression - step
        elseif rt.graphics.get_fps() >= 0.99 * rt.graphics.get_target_fps() then
            self._current_compression = self._current_compression + step
        end

        self._current_compression = clamp(self._current_compression, 0.25, 1)
        if self._current_compression ~= before then
            self:reformat()
        end

        self._dynamic_resolution_freeze_count = 0
    end
end

--- @override
function rt.Background:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    if self._implementation ~= nil then
        self._implementation:realize()
    end
end

--- @override
function rt.Background:size_allocate(x, y, width, height)
    self._position_x, self._position_y = x, y
    local w, h = self._current_compression * width, self._current_compression * height
    self._render_texture = rt.RenderTexture(w, h)
    --self._render_texture:set_scale_mode(rt.TextureScaleMode.LINEAR)
    self._shape:set_texture(self._render_texture)

    for shape in range(self._shape, self._mask_shape) do
        shape:set_vertex_position(1, x, y)
        shape:set_vertex_position(2, x + width, y)
        shape:set_vertex_position(3, x + width, y + height)
        shape:set_vertex_position(4, x, y + height)
    end

    if self._implementation ~= nil then
        self._implementation:size_allocate(0, 0, width, height)
    end

    self:_update_render_texture()
end

--- @override
function rt.Background:draw()
    if self._is_realized ~= true or self._implementation == nil then return end

    self._shape:draw()

    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
    self._mask_shape:draw()
    rt.graphics.set_blend_mode()
end
