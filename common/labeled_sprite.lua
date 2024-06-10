rt.settings.sprite_with_label = {
    font = rt.settings.font.default_small
}

--- @class rt.LabeledSprite
rt.LabeledSprite = meta.new_type("LabeledSprite", rt.Widget, function(sprite_id, sprite_index)
    return meta.new(rt.LabeledSprite, {
        _shape = {},       -- rt.VertexShape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _sprite_id = sprite_id,
        _sprite_index = which(sprite_index, 1),

        _label = {},  -- rt.Label
        _label_text = "",
        _label_is_visible = true,

        _opacity = 1,
        _scale = 1,
        _sprite_scale = 1, -- multiplier for sprite resolution
    })
end)

--- @override
function rt.LabeledSprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._spritesheet = rt.SpriteAtlas:get(self._sprite_id)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._shape:set_texture(self._spritesheet:get_texture())
    local frame = self._spritesheet:get_frame(self._sprite_index)
    self._shape:reformat_texture_coordinates(
        frame.x, frame.y,
        frame.x + frame.width, frame.y,
        frame.x + frame.width, frame.y + frame.height,
        frame.x, frame.y + frame.height
    )

    self._label = rt.Label(self._label_text, rt.settings.font.default_small, rt.settings.font.default_mono_small)
    self._label:realize()

    self:set_opacity(self._opacity)
    self:set_scale(self._scale)
end

--- @override
function rt.LabeledSprite:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    local res_x, res_y = self._spritesheet:get_frame_size()
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local scale = self._scale * self._sprite_scale
    self._shape:reformat_vertex_positions(
        center_x - 0.5 * res_x * scale, center_y - 0.5 * res_y * scale,
        center_x + 0.5 * res_x * scale, center_y - 0.5 * res_y * scale,
        center_x + 0.5 * res_x * scale, center_y + 0.5 * res_y * scale,
        center_x - 0.5 * res_x * scale, center_y + 0.5 * res_y * scale
    )

    local label_w, label_h = self._label:measure()

    self._label:fit_into(
        x + res_x * scale - 1 * label_w,
        y + res_y * scale - 1 * label_h,
        POSITIVE_INFINITY, label_h
    )
end

--- @override
function rt.LabeledSprite:draw()
    if self._is_realized ~= true then return end
    self._shape:draw()

    if self._label_is_visible then
        self._label:draw()
    end
end

--- @brief
function rt.LabeledSprite:set_label(text)
    self._label_text = text
    if self._is_realized then
        self._label:set_text(text)
        self:reformat()
    end
end

--- @brief
function rt.LabeledSprite:set_opacity(alpha)
    self._opacity = alpha
    if self._is_realized then
        self._shape:set_opacity(alpha)
        self._label:set_opacity(alpha)
    end
end

--- @brief
function rt.LabeledSprite:set_scale(scale)
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

--- @override
function rt.LabeledSprite:measure()
    local w, h = self._spritesheet:get_frame_size()
    return w * self._sprite_scale, h * self._sprite_scale
end

--- @brief
function rt.LabeledSprite:set_sprite_scale(scale)
    self._sprite_scale = scale
    self:reformat()
end