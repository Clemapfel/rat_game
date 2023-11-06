rt.settings.sprite_scale = {}
rt.settings.sprite_scale.rail_left_id = "rail_left"
rt.settings.sprite_scale.rail_left_right_id = "rail_horizontal"
rt.settings.sprite_scale.rail_right_id = "rail_right"
rt.settings.sprite_scale.rail_top_id = "rail_top"
rt.settings.sprite_scale.rail_top_bottom_id = "rail_vertical"
rt.settings.sprite_scale.rail_bottom_id = "rail_bottom"
rt.settings.sprite_scale.slider_id = "slider"

--- @class rt.SpriteScale
rt.SpriteScale = meta.new_type("SpriteScale", function(spritesheet, lower, upper, value, orientation)
    meta.assert_isa(spritesheet, rt.Spritesheet)
    meta.assert_number(lower, upper)
    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end

    if meta.is_nil(orientation) then
        orientation = rt.Orientation.HORIZONTAL
    end

    local out = meta.new(rt.SpriteScale, {
        _spritesheet = spritesheet,
        _left = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_left_id),
        _left_right = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_left_right_id),
        _right = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_right_id),
        _top = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_top_id),
        _top_bottom = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_top_bottom_id),
        _bottom = rt.Sprite(spritesheet, rt.settings.sprite_scale.rail_bottom_id),
        _slider = rt.Sprite(spritesheet, rt.settings.sprite_scale.slider_id),
        _lower = lower,
        _upper = upper,
        _value = value,
        _orientation = orientation
    }, rt.Drawable, rt.Widget)
    return out
end)

--- @overload rt.Drawable.draw
function rt.SpriteScale:draw()
    meta.assert_isa(self, rt.SpriteScale)
    if self._orientation == rt.Orientation.HORIZONTAL then
        self._left_right:draw()
        self._left:draw()
        self._right:draw()
    elseif self._orientation == rt.Orientation.VERTICAL then
        self._top_bottom:draw()
        self._top:draw()
        self._bottom:draw()
    end

    self._slider:draw()
end

--- @brief [internal] reposition slider element
function rt.SpriteScale:_update_slider()
    meta.assert_isa(self, rt.SpriteScale)

    local frame_w, frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.slider_id)
    local slider_x, slider_y, slider_w, slider_h
    if self._orientation == rt.Orientation.HORIZONTAL then
        local x, y = self._left:get_position()
        local w = self._right:get_position() + self._right:get_width() - x

        if self:get_expand_vertically() then
            slider_h = self._left_right:get_height()
            slider_w = frame_w * (slider_h / frame_h)
        else
            slider_h = frame_h
            slider_w = frame_w
        end

        slider_x = x + ((self._value - self._lower) / (self._upper - self._lower)) * w - 0.5 * slider_w
        slider_y = ({self._left_right:get_position()})[2] + self._left_right:get_height() * 0.5 - 0.5 * slider_h

    elseif self._orientation == rt.Orientation.VERTICAL then
        local x, y = self._top:get_position()
        local h = ({self._bottom:get_position()})[2] + self._bottom:get_height() - y

        if self:get_expand_horizontally() then
            slider_w = self._top_bottom:get_width()
            slider_h = frame_h * (slider_w / frame_w)
        else
            slider_w = frame_w
            slider_h = frame_h
        end

        slider_y = y + ((self._value - self._lower) / (self._upper - self._lower)) * h - 0.5 * slider_h
        slider_x = ({self._top_bottom:get_position()})[1] + self._top_bottom:get_width() * 0.5 - 0.5 * slider_w
    end

    self._slider:fit_into(rt.AABB(slider_x, slider_y, slider_w, slider_h))
end

--- @overload rt.Widget.size_allocate
function rt.SpriteScale:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.SpriteScale)

    local left_m, right_m, top_m, bottom_m = self:get_margin_left(), self:get_margin_right(), self:get_margin_top(), self:get_margin_bottom()

    if self._orientation == rt.Orientation.HORIZONTAL then
        local left_frame_w, left_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_left_id)
        local right_frame_w, right_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_right_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_left_right_id)

        local left_w, left_h, right_w, right_h, center_w, center_h

        if self:get_expand_vertically() then
            local h = height - top_m - bottom_m
            left_h = h
            left_w = left_frame_w * (left_h / left_frame_h)
            right_h = h
            right_w = right_frame_w * (right_h / left_frame_h)
            center_h = math.max(h, center_frame_h)
        else
            left_h = left_frame_h
            left_w = left_frame_w
            right_h = right_frame_h
            right_w = right_frame_w
            center_h = center_frame_h
        end

        center_w = clamp(width - left_m - right_m - left_w - right_w, 0)
        self._left:fit_into(rt.AABB(x + left_m, y + 0.5 * height - 0.5 * left_h, left_w, left_h))
        self._left_right:fit_into(rt.AABB(x + left_m + left_w, y + 0.5 * height - 0.5 * center_h, center_w, center_h))
        self._right:fit_into(rt.AABB(x + width - right_m - right_w, y + 0.5 * height - 0.5 * right_h, right_w, right_h))
    elseif self._orientation == rt.Orientation.VERTICAL then
        local top_frame_w, top_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_top_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_top_bottom_id)
        local bottom_frame_w, bottom_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_scale.rail_bottom_id)

        local top_w, top_h, center_w, center_h,  bottom_w, bottom_h

        if self:get_expand_horizontally() then
            local w = width - left_m - right_m
            top_w = w
            top_h = top_frame_h * (top_w / top_frame_w)
            bottom_w = w
            bottom_h = bottom_frame_h * (bottom_w / bottom_frame_w)
            center_w = math.max(w, center_frame_w)
        else
            top_w = top_frame_w
            top_h = top_frame_h
            bottom_w = bottom_frame_w
            bottom_h = bottom_frame_h
            center_w = center_frame_w
        end

        center_h = clamp(height - top_m - bottom_m - top_h - bottom_h)
        self._top:fit_into(rt.AABB(x + 0.5 * width - 0.5 * top_w, y + top_m, top_w, top_h))
        self._top_bottom:fit_into(rt.AABB(x + 0.5 * width - 0.5 * center_w, y + top_m + top_h, center_w, center_h))
        self._bottom:fit_into(rt.AABB(x + 0.5 * width - 0.5 * bottom_w, y + height - bottom_m - bottom_h, bottom_w, bottom_h))
    end

    self:_update_slider()
end

--- @overload rt.Widget.realize
function rt.SpriteScale:realize()
    meta.assert_isa(self, rt.SpriteScale)

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
function rt.SpriteScale:set_value(value)
    meta.assert_isa(self, rt.SpriteScale)
    meta.assert_number(value)

    self._value = clamp(value, self._lower, self._upper)
    self:_update_slider()
end

--- @brief get scale value
--- @return Number
function rt.SpriteScale:get_value()
    meta.assert_isa(self, rt.SpriteScale)
    return self._value
end

--- @brief set orientation
--- @param orientation rt.Orientation
function rt.SpriteScale:set_orientation(orientation)
    meta.assert_isa(self, rt.SpriteScale)
    meta.assert_enum(orientation, rt.Orientation)
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.SpriteScale:get_orientation()
    meta.assert_isa(self, rt.SpriteScale)
    return self._orientation
end


--- @brief [internal] test
function rt.test.sprite_scale()
    error("TODO")
end
