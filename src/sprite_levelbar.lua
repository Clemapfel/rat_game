rt.settings.levelbar = {}
rt.settings.levelbar.rail_left_id = "rail_left"
rt.settings.levelbar.rail_left_right_id = "rail_horizontal"
rt.settings.levelbar.rail_right_id = "rail_right"
rt.settings.levelbar.rail_top_id = "rail_top"
rt.settings.levelbar.rail_top_bottom_id = "rail_vertical"
rt.settings.levelbar.rail_bottom_id = "rail_bottom"
rt.settings.levelbar.bar_left_id = "bar_left"
rt.settings.levelbar.bar_left_right_id = "bar_horizontal"
rt.settings.levelbar.bar_right_id = "bar_right"
rt.settings.levelbar.bar_top_id = "bar_top"
rt.settings.levelbar.bar_top_bottom_id = "bar_vertical"
rt.settings.levelbar.bar_bottom_id = "bar_bottom"

--- @class rt.Levelbar
rt.Levelbar = meta.new_type("Levelbar", function(spritesheet, lower, upper, value, orientation)
    meta.assert_isa(spritesheet, rt.Spritesheet)
    meta.assert_number(lower, upper)
    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end

    if meta.is_nil(orientation) then
        orientation = rt.Orientation.HORIZONTAL
    end

    local out = meta.new(rt.Levelbar, {
        _spritesheet = spritesheet,
        _rail_left = rt.Sprite(spritesheet, rt.settings.levelbar.rail_left_id),
        _rail_left_right = rt.Sprite(spritesheet, rt.settings.levelbar.rail_left_right_id),
        _rail_right = rt.Sprite(spritesheet, rt.settings.levelbar.rail_right_id),
        _rail_top = rt.Sprite(spritesheet, rt.settings.levelbar.rail_top_id),
        _rail_top_bottom = rt.Sprite(spritesheet, rt.settings.levelbar.rail_top_bottom_id),
        _rail_bottom = rt.Sprite(spritesheet, rt.settings.levelbar.rail_bottom_id),
        _bar_left = rt.Sprite(spritesheet, rt.settings.levelbar.bar_left_id),
        _bar_left_right = rt.Sprite(spritesheet, rt.settings.levelbar.bar_left_right_id),
        _bar_right = rt.Sprite(spritesheet, rt.settings.levelbar.bar_right_id),
        _bar_top = rt.Sprite(spritesheet, rt.settings.levelbar.bar_top_id),
        _bar_top_bottom = rt.Sprite(spritesheet, rt.settings.levelbar.bar_top_bottom_id),
        _bar_bottom = rt.Sprite(spritesheet, rt.settings.levelbar.bar_bottom_id),
        _lower = lower,
        _upper = upper,
        _value = value,
        _orientation = orientation
    }, rt.Drawable, rt.Widget)
    return out
end)

--- @overload rt.Drawable.draw
function rt.Levelbar:draw()
    meta.assert_isa(self, rt.Levelbar)
    if self._orientation == rt.Orientation.HORIZONTAL then
        self._rail_left_right:draw()
        self._rail_left:draw()
        self._rail_right:draw()

        if self._value > self._lower then
            self._bar_left_right:draw()
            self._bar_left:draw()
            self._bar_right:draw()
        end

    elseif self._orientation == rt.Orientation.VERTICAL then
        self._rail_top_bottom:draw()
        self._rail_top:draw()
        self._rail_bottom:draw()

        if self._value > self._lower then
            self._bar_top_bottom:draw()
            self._bar_top:draw()
            self._bar_bottom:draw()
        end
    end
end

--- @brief [internal] reposition slider element
function rt.Levelbar:_update_bar()
    meta.assert_isa(self, rt.Levelbar)

    if self._orientation == rt.Orientation.HORIZONTAL then
        local x, y = self._rail_left:get_position()
        local w = self._rail_right:get_position() + self._rail_right:get_width() - x
        local h = self._rail_left_right:get_height()

        local frame_w, frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.bar_left_id)
        local slider_w, slider_h
        if self:get_expand_vertically() then
            slider_h = self._rail_left_right:get_height()
            slider_w = frame_w * (slider_h / frame_h)
        else
            slider_h = frame_h
            slider_w = frame_w
        end

        --self._bar_left:fit_into(rt.AABB(x, y, slider_w, slider_h))
        self._bar_left_right:fit_into(rt.AABB(x, y, ((self._value - self._lower) / (self._upper - self._lower)) * w, h))
        --self._bar_right:fit_into(rt.AABB(x + self._bar_left_right:get_width() - slider_w, y, slider_w, slider_h))
    end
end

--- @overload rt.Widget.size_allocate
function rt.Levelbar:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Levelbar)

    local left_m, right_m, top_m, bottom_m = self:get_margin_left(), self:get_margin_right(), self:get_margin_top(), self:get_margin_bottom()

    if self._orientation == rt.Orientation.HORIZONTAL then
        local left_frame_w, left_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_left_id)
        local right_frame_w, right_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_right_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_left_right_id)

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
        self._rail_left:fit_into(rt.AABB(x + left_m, y + 0.5 * height - 0.5 * left_h, left_w, left_h))
        self._rail_left_right:fit_into(rt.AABB(x + left_m + left_w, y + 0.5 * height - 0.5 * center_h, center_w, center_h))
        self._rail_right:fit_into(rt.AABB(x + width - right_m - right_w, y + 0.5 * height - 0.5 * right_h, right_w, right_h))
    elseif self._orientation == rt.Orientation.VERTICAL then
        local top_frame_w, top_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_top_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_top_bottom_id)
        local bottom_frame_w, bottom_frame_h = self._spritesheet:get_frame_size(rt.settings.levelbar.rail_bottom_id)

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
        self._rail_top:fit_into(rt.AABB(x + 0.5 * width - 0.5 * top_w, y + top_m, top_w, top_h))
        self._rail_top_bottom:fit_into(rt.AABB(x + 0.5 * width - 0.5 * center_w, y + top_m + top_h, center_w, center_h))
        self._rail_bottom:fit_into(rt.AABB(x + 0.5 * width - 0.5 * bottom_w, y + height - bottom_m - bottom_h, bottom_w, bottom_h))
    end

    self:_update_bar()
end

--- @overload rt.Widget.realize
function rt.Levelbar:realize()
    meta.assert_isa(self, rt.Levelbar)

    self._rail_left:realize()
    self._rail_left_right:realize()
    self._rail_right:realize()
    self._rail_top:realize()
    self._rail_top_bottom:realize()
    self._rail_bottom:realize()
    self._bar_left:realize()
    self._bar_left_right:realize()
    self._bar_right:realize()
    self._bar_top:realize()
    self._bar_top_bottom:realize()
    self._bar_bottom:realize()

    self:_update_bar()
    rt.Widget.realize(self)
end

--- @brief set levelbar value
--- @param value Number
function rt.Levelbar:set_value(value)
    meta.assert_isa(self, rt.Levelbar)
    meta.assert_number(value)

    self._value = clamp(value, self._lower, self._upper)
    self:_update_bar()
end

--- @brief get levelbar value
--- @return Number
function rt.Levelbar:get_value()
    meta.assert_isa(self, rt.Levelbar)
    return self._value
end

--- @brief set orientation
--- @param orientation rt.Orientation
function rt.Levelbar:set_orientation(orientation)
    meta.assert_isa(self, rt.Levelbar)
    meta.assert_enum(orientation, rt.Orientation)
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.Levelbar:get_orientation()
    meta.assert_isa(self, rt.Levelbar)
    return self._orientation
end
