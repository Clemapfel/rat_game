rt.settings.battle.status_bar_element = {
    font = rt.settings.font.default_mono_small
}

--- @class bt.StatusBarElement
bt.StatusBarElement = meta.new_type("StatusBarElement", rt.Widget, function(entity, status)
    return meta.new(bt.StatusBarElement, {
        _entity = entity,
        _status = status,

        _shape = {},      -- rt.VertexShape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _n_turns_left = 0,
        _n_turns_left_label_visible = true,
        _n_turns_left_label = {}, -- rt.Glyph

        _opacity = 1,
        _scale = 1,
        _hide_n_turns = 1,

        _debug_shape = {}, -- rt.Shape

        _tooltip = {
            is_realized = false
        }
    })
end)

--- @brief [internal]
function bt.StatusBarElement:set_elapsed(n)
    self._n_turns_left = n
    local max = self._status.max_duration
    local current = self._n_turns_left
    local text = tostring(max - current)
    if max - current < 0 then
        text = ""
        rt.warning("In bt.StatusBarElement:set_elapsed: number of leftover for status `" .. self._status.id .. "` on entity `" .. self._entity:get_id() .. "`) turns is less than 0")
    end

    if self._is_realized == true then
        if meta.isa(self._n_turns_left_label, rt.Glyph) then
            self._n_turns_left_label:set_text(text)
        end
    end
end

--- @brief
function bt.StatusBarElement:realize()
    if self._is_realized == true then return end
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
        self:set_elapsed(self._n_turns_left)
    end

    self:set_opacity(self:get_opacity())
    self:set_scale(self:get_scale())
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
    if self._is_realized == true then
        self._shape:draw()
        if self._n_turns_left_label_visible and not self._hide_n_turns then
            self._n_turns_left_label:draw()
        end

        if rt.current_scene:get_debug_draw_enabled() then
            self._debug_shape:draw()
        end
    end
end

--- @brief
function bt.StatusBarElement:_draw_sprite()
    if self._is_realized == true then
        self._shape:draw()
    end

    if rt.current_scene:get_debug_draw_enabled() then
        self._debug_shape:draw()
    end
end

--- @brief
function bt.StatusBarElement:_draw_label()
    if self._n_turns_left_label_visible and not self._hide_n_turns then
        self._n_turns_left_label:draw()
    end
end

--- @brief
function bt.StatusBarElement:set_opacity(alpha)
    self._opacity = clamp(alpha, 0, 1)

    if self._is_realized == true then
        self._shape:set_opacity(self._opacity)
        if self._n_turns_left_label_visible then
            self._n_turns_left_label:set_opacity(self._opacity)
        end
    end
end

--- @brief
function bt.StatusBarElement:get_opacity()
    return self._opacity
end

--- @brief
function bt.StatusBarElement:set_scale(scale)
    self._scale = clamp(scale, 0)
    if self._is_realized == true then
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

--- @brief
function bt.StatusBarElement:set_hide_n_turns_left(b)
    self._hide_n_turns = b
end

--- @brief
function bt.StatusBarElement:get_hide_n_turns_left()
    return self._hide_n_turns
end