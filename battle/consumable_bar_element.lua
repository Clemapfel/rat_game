rt.settings.battle.consumable_indicator = {
    font = rt.settings.font.default_mono
}

bt.ConsumableIndicator = meta.new_type("ConsumableIndicator", rt.Widget, rt.Animation, function(consumable)
    return meta.new(bt.ConsumableIndicator, {
        _consumable = consumable,

        _shape = {},       -- rt.VertexShape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _n_left = 0,
        _n_left_label_visible = true,
        _n_left_label = {}, -- rt.Glyph

        _opacity = 1,
        _scale = 1
    })
end)

--- @brief
function bt.ConsumableIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    self._spritesheet = rt.SpriteAtlas:get(sprite_id)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._shape:set_texture(self._spritesheet:get_texture())
    local frame = self._spritesheet:get_frame(sprite_index)
    self._shape:reformat_texture_coordinates(
        frame.x, frame.y,
        frame.x + frame.width, frame.y,
        frame.x + frame.width, frame.y + frame.height,
        frame.x, frame.y + frame.height
    )

    self._n_left_label = rt.Glyph(rt.settings.battle.consumable_indicator.font, tostring(self._n_left), {
        is_outlined = true,
        outline_color = rt.Palette.BLACK
    })

    self:set_n_left(self._n_left)
    self:set_opacity(self._opacity)
    self:set_scale(self._scale)
end

--- @brief
function bt.ConsumableIndicator:size_allocate(x, y, width, height)
    if not self._is_realized == true then return end

    local res_x, res_y = self._spritesheet:get_frame_size()
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    self._shape:reformat_vertex_positions(
        center_x - 0.5 * res_x, center_y - 0.5 * res_y,
        center_x + 0.5 * res_x, center_y - 0.5 * res_y,
        center_x + 0.5 * res_x, center_y + 0.5 * res_y,
        center_x - 0.5 * res_x, center_y + 0.5 * res_y
    )

    local glyph_w, glyph_h = self._n_left_label:get_size()
    self._n_left_label:set_position(x + width - glyph_w, y + height - 0.75 * glyph_h)
end

--- @brief
function bt.ConsumableIndicator:draw()
    if not self._is_realized == true then return end
    self._shape:draw()

    if self._n_left_label_visible then
        self._n_left_label:draw()
    end
end

--- @brief
function bt.ConsumableIndicator:set_opacity(alpha)
    self._opacity = alpha
    if self._is_realized == true then
        self._shape:set_opacity(alpha)
    end
end

--- @brief
function bt.ConsumableIndicator:set_scale(scale)
    self._scale = scale
    if self._is_realized then
        local center_x, center_y = self._shape:get_centroid()
        local res_x, res_y = self._spritesheet:get_frame_size()
        self._shape:reformat_vertex_positions(
            center_x - 0.5 * res_x * scale, center_y - 0.5 * res_y * scale,
            center_x + 0.5 * res_x * scale, center_y - 0.5 * res_y * scale,
            center_x + 0.5 * res_x * scale, center_y + 0.5 * res_y * scale,
            center_x - 0.5 * res_x * scale, center_y + 0.5 * res_y * scale
        )
    end
end

--- @brief
function bt.ConsumableIndicator:get_scale()
    return self._scale
end

--- @brief
function bt.ConsumableIndicator:set_n_left(n)
    self._n_left = n
    self._n_left_label_visible = n ~= POSITIVE_INFINITY
    if self._is_realized then
        self._n_left_label:set_text(tostring(n))
        self:reformat()
    end
end