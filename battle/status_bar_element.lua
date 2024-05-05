rt.settings.battle.status_bar_element = {
    font = rt.settings.font.default_mono_small
}

--- @class bt.StatusBarElement
bt.StatusBarElement = meta.new_type("StatusBarElement", rt.Widget, function(status)
    return meta.new(bt.StatusBarElement, {
        _status = status,

        _shape = {},       -- rt.VertexShape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _n_turns_left = 0,
        _n_turns_left_label_visible = true,
        _n_turns_left_label = {}, -- rt.Glyph

        _opacity = 1,
        _scale = 1
    })
end)

--- @brief
function bt.StatusBarElement:set_elapsed(n)
    self._n_turns_left = n
    if self._is_realized == true then
        self._n_turns_left_label:set_text(tostring(self._status:get_max_duration() - self._n_turns_left))
    end
end

--- @brief
function bt.StatusBarElement:set_opacity(alpha)
    self._opacity = alpha
    if self._is_realized then
        self._shape:set_opacity(self._opacity)
        self._n_turns_left_label:set_opacity(self._opacity)
    end
end

--- @brief
function bt.StatusBarElement:set_scale(scale)
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
function bt.StatusBarElement:get_scale()
    return self._scale
end

--- @override
function bt.StatusBarElement:realize()
    if self._is_realized then return end

    self._is_realized = true
    local sprite_id, sprite_index = self._status:get_sprite_id()
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

    self._n_turns_left_label_visible = self._status.max_duration ~= POSITIVE_INFINITY
    local text = tostring(self._status:get_max_duration() - self._n_turns_left)
    self._n_turns_left_label = rt.Glyph(
        rt.settings.battle.status_bar_element.font,
        text,
        {
            is_outlined = true,
            outline_color = rt.Palette.BLACK,
            font_style = rt.FontStyle.BOLD
        }
    )

    self:set_opacity(self._opacity)
    self:set_scale(self._scale)
end


--- @brief
function bt.StatusBarElement:size_allocate(x, y, width, height)
    if self._is_realized == true then
        -- display icon centered at original resolution to avoid artifacting
        local res_x, res_y = self._spritesheet:get_frame_size()
        local center_x, center_y = x + 0.5 * width, y + 0.5 * height
        self._shape:reformat_vertex_positions(
            center_x - 0.5 * res_x, center_y - 0.5 * res_y,
            center_x + 0.5 * res_x, center_y - 0.5 * res_y,
            center_x + 0.5 * res_x, center_y + 0.5 * res_y,
            center_x - 0.5 * res_x, center_y + 0.5 * res_y
        )

        if self._n_turns_left_label_visible then
            -- label should be entirely within bounds to avoid overlap in box
            local label_w, label_h = self._n_turns_left_label:get_size()
            self._n_turns_left_label:set_position(
                x + width - 0.8 * label_w,
                y + height - 0.6 * label_h
            )
        end

        self._debug_shape = rt.Rectangle(x, y, width, height)
        self._debug_shape:set_is_outline(true)
    end
end

--- @brief
function bt.StatusBarElement:draw()
    if self._is_realized ~= true then return end
    self:_draw_shape()
    self:_draw_label()
end

--- @brief
function bt.StatusBarElement:_draw_sprite()
    self._shape:draw()
end

--- @brief
function bt.StatusBarElement:_draw_label()
    if self._n_turns_left_label_visible then
        self._n_turns_left_label:draw()
    end
end