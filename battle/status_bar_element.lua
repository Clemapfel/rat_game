rt.settings.battle.status_bar_element = {
    font = rt.settings.font.default_mono_small
}

--- @class bt.StatusBarElement
bt.StatusBarElement = meta.new_type("StatusBarElement", rt.Widget, function(entity, status)
    return meta.new(bt.StatusBarElement, {
        _entity = entity,
        _status = status,

        _shape = {},      -- rt.Shape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _n_turns_left_label_visible = true,
        _n_turns_left_label = {}, -- rt.Glyph

        _tooltip = {
            is_realized = false
        }
    })
end)

--- @brief [internal]
function bt.StatusBarElement:_update_n_turns_left_label()
    local max = self._status.max_duration
    local current = self._entity.status[self._status]

    local text = tostring(max - current)
    if max - current < 0 then
        text = ""
        rt.warning("In bt.StatusBarElement:_update_n_turns_left_label: number of leftover for status `" .. self._status.id .. "` on entity `" .. self._entity:get_id() .. "`) turns is less than 0")
    end
    self._n_turns_left_label:set_text(text)
end

--- @brief
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
    if self._n_turns_left_label_visible then
        self._n_turns_left_label = rt.Glyph(
            rt.settings.battle.status_bar_element.font,
            tostring(self._status.max_duration),
            {
                is_outlined = true,
                outline_color = rt.Palette.BLACK,
                font_style = rt.FontStyle.BOLD
            }
        )
        self:_update_n_turns_left_label()
    end
end

--- @brief
function bt.StatusBarElement:size_allocate(x, y, width, height)
    if self._is_realized then

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
                x + width - 1.1 * label_w,
                y + height - 1 * label_h
            )
        end
    end
end

--- @brief
function bt.StatusBarElement:draw()
    if self._is_realized then
        self._shape:draw()
        if self._n_turns_left_label_visible then
            self._n_turns_left_label:draw()
        end
    end
end

--- @brief
function bt.StatusBarElement:set_opacity(alpha)
    self._shape:set_opacity(alpha)
    if self._n_turns_left_label_visible then
        self._n_turns_left_label:set_opacity(alpha)
    end
end