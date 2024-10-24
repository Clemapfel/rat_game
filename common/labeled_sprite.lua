rt.settings.sprite_with_label = {
    font = rt.settings.font.default_small
}

--- @class rt.LabeledSprite
rt.LabeledSprite = meta.new_type("LabeledSprite", rt.Widget, function(sprite_id, sprite_index)
    return meta.new(rt.LabeledSprite, {
        _sprite = rt.Sprite(sprite_id, sprite_index),

        _label = {},  -- rt.Label
        _label_text = "",
        _label_is_visible = true,

        _scale = 1,
        _sprite_scale = 1,
        _opacity = 1,
    })
end)

--- @override
function rt.LabeledSprite:realize()
    if self:already_realized() then return end

    self._sprite:realize()
    self._label = rt.Label(self._label_text)
    self._label:realize()

    self:set_opacity(self._opacity)
    self:set_scale(self._scale)
end

--- @override
function rt.LabeledSprite:size_allocate(x, y, width, height)
    local res_x, res_y = self._sprite:get_resolution()
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local scale = self._scale * self._sprite_scale

    self._sprite:fit_into(x, y, width, height)
    local label_w, label_h = self._label:measure()
    self._label:fit_into(
        x + width - 1 * label_w,
        y + height - 1 * label_h,
        POSITIVE_INFINITY, label_h
    )
end

--- @override
function rt.LabeledSprite:draw()
    if self._is_realized then
        self._sprite:draw()

        if self._label_is_visible == true then
            self._label:draw()
        end
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
        self._sprite:set_opacity(alpha)
        self._label:set_opacity(alpha)
    end
end

--- @brief
function rt.LabeledSprite:set_scale(scale)
    self._scale = scale
end

--- @brief
function rt.LabeledSprite:get_resolution()
    return self._sprite:get_resolution()
end

--- @brief
function rt.LabeledSprite:set_label_is_visible(b)
    self._label_is_visible = b
end

--- qbrief
function rt.LabeledSprite:set_sprite_scale(b)
    rt.error("TODO refactor")
end

--- @brief
function rt.LabeledSprite:get_sprite()
    return self._sprite
end

--- @brief
function rt.LabeledSprite:get_label()
    return self._label
end