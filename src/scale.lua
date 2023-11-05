rt.settings.scale = {}
rt.settings.scale.rail_left_id = "rail_left"
rt.settings.scale.rail_left_right_id = "rail_horizontal"
rt.settings.scale.rail_right_id = "rail_right"
rt.settings.scale.rail_top_id = "rail_top"
rt.settings.scale.rail_top_bottom_id = "rail_vertical"
rt.settings.scale.rail_bottom_id = "rail_bottom"
rt.settings.scale.slider_id = "slider"

--- @class rt.Scale
rt.Scale = meta.new_type("Scale", function(spritesheet, lower, upper, value, orientation)
    meta.assert_isa(spritesheet, rt.Spritesheet)
    meta.assert_number(lower, upper)
    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end

    if meta.is_nil(orientation) then
        orientation = rt.Orientation.HORIZONTAL
    end

    local self = meta.new(rt.Scale, {
        _spritesheet = spritesheet,
        _left = rt.Sprite(spritesheet, rt.settings.scale.rail_left_id),
        _left_right = rt.Sprite(spritesheet, rt.settings.scale.rail_left_right_id),
        _right = rt.Sprite(spritesheet, rt.settings.scale.rail_right_id),
        _top = rt.Sprite(spritesheet, rt.settings.scale.rail_top_id),
        _top_bottom = rt.Sprite(spritesheet, rt.settings.scale.rail_top_bottom_id),
        _bottom = rt.Sprite(spritesheet, rt.settings.scale.rail_bottom_id),
        _slider = rt.Sprite(spritesheet, rt.settings.scale.slider_id),
        _lower = lower,
        _upper = upper,
        _value = value,
        _orientation = orientation
    }, rt.Drawable, rt.Widget)

    -- allow squishing of center pieces
    self._left_right:set_minimum_size(0, self._spritesheet:get_frame_height(rt.settings.scale.rail_left_right_id))
    self._top_bottom:set_minimum_size(0, self._spritesheet:get_frame_height(rt.settings.scale.rail_top_bottom_id))
    return self
end)

--- @overload rt.Drawable.draw
function rt.Scale:draw()
    meta.assert_isa(self, rt.Scale)
    if self._orientation == rt.Orientation.HORIZONTAL then
        self._left_right:draw()
        self._left:draw()
        self._right:draw()
        self._slider:draw()
    elseif self._orientation == rt.Orientation.VERTICAL then
        self._top_bottom:draw()
        self._top:draw()
        self._bottom:draw()
        self._slider:draw()
    end
end

--- @brief [internal] reposition slider element
function rt.Scale:_update_slider()
    meta.assert_isa(self, rt.Scale)
    local x, y = self._left:get_position()
    local w = self._right:get_position() + self._right:get_width() - x

    local slider_w, slider_h
    local frame_w, frame_h = self._spritesheet:get_frame_size(rt.settings.scale.slider_id)
    if self:get_expand_vertically() then
        slider_h = self._left_right:get_height()
        slider_w = frame_w * (slider_h / frame_h)
    else
        slider_h = frame_h
        slider_w = frame_w
    end

    local slider_x = x + ((self._value - self._lower) / (self._upper - self._lower)) * w - 0.5 * slider_w
    local slider_y = ({self._left_right:get_position()})[2] + self._left_right:get_height() * 0.5 - 0.5 * slider_h
    self._slider:fit_into(rt.AABB(slider_x, slider_y, slider_w, slider_h))
end

--- @overload rt.Widget.size_allocate
function rt.Scale:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Scale)

    local left_frame_w, left_frame_h = self._spritesheet:get_frame_size(rt.settings.scale.rail_left_id)
    local right_frame_w, right_frame_h = self._spritesheet:get_frame_size(rt.settings.scale.rail_right_id)
    local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.scale.rail_left_right_id)

    local left_m, right_m, top_m, bottom_m = self:get_margin_left(), self:get_margin_right(), self:get_margin_top(), self:get_margin_bottom()
    local left_w, left_h, right_w, right_h, center_w, center_h
    if self:get_expand_vertically() then
        local h = height - top_m - bottom_m
        left_h = h
        left_w = left_frame_w * (left_h / left_frame_h)
        right_h = h
        right_w = right_frame_w * (right_h / left_frame_h)
        center_h = h
    else
        left_h = left_frame_h
        left_w = left_frame_w
        right_h = right_frame_h
        right_w = right_frame_w
        center_h = center_frame_h
    end

    center_w = clamp(width - self:get_margin_left() - self:get_margin_top() - left_w - right_w, 0)
    self._left:fit_into(rt.AABB(x + left_m, y + 0.5 * left_h, left_w, left_h))
    self._left_right:fit_into(rt.AABB(x + left_m + left_w, y + 0.5 * center_h, center_w, center_h))
    self._right:fit_into(rt.AABB(x + width - right_m - right_w, y + 0.5 * right_h, right_w, right_h))

    self:_update_slider()
end

--- @overload rt.Widget.realize
function rt.Scale:realize()
    meta.assert_isa(self, rt.Scale)

    self._left:realize()
    self._left_right:realize()
    self._right:realize()
    self._top:realize()
    self._top_bottom:realize()
    self._bottom:realize()
    self._slider:realize()
    
    self:_update_slider()
    rt.Widget.realize(self)
end

--- @brief set scale value
--- @param value Number
function rt.Scale:set_value(value)
    meta.assert_isa(self, rt.Scale)
    meta.assert_number(value)

    self._value = clamp(value, self._lower, self._upper)
    self:_update_slider()
end

--- @brief get scale value
--- @return Number
function rt.Scale:get_value()
    meta.assert_isa(self, rt.Scale)
    return self._value
end
