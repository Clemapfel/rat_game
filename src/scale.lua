--- @class rt.Scale
rt.Scale = meta.new_type("Scale", function(lower, upper, value)
    local out = meta.new(rt.SpinButton, {
        _lower = math.min(lower, upper),
        _upper = math.max(upper, lower),
        _value = ternary(meta.is_nil(value), mix(lower, upper, 0.5), value)
        _rail_center = rt.Rectangle(0, 0, 1, 1),
        _rail_start = rt.Circle(0, 0, 1, 16),
        _rail_end = rt.Circle(0, 0, 1, 16),
        _rail_outline = rt.Rectangle(0, 0, 1, 1),
        _slider = rt.Circle(0, 0, 1, 16),
        _slider_outline = rt.Circle(0, 0, 1, 16)
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)
end)

--- @overload rt.Drawable.draw
function rt.Scale:draw()
    meta.assert_isa(self, rt.SpriteScale)
    self._rail_star:draw()
    self._rail_end:draw()
    self._rail_center:draw()
    self._rail_outline:draw()

    self._slider:draw()
    self._slider_outline:draw()
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