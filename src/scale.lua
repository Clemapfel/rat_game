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

    return meta.new(rt.Scale, {
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
end)

--- @overload rt.Drawable.draw
function rt.Scale:draw()
    meta.assert_isa(self, rt.Scale)
    if self._orientation == rt.Orientation.HORIZONTAL then
        --self._left_right:draw()
        self._left:draw()
        self._right:draw()
        self._slider:draw()
    elseif self._orientation == rt.Orientation.VERTICAL then
        --sself._top_bottom:draw()
        self._top:draw()
        self._bottom:draw()
        self._slider:draw()
    end
end

--- @brief [internal] reposition slider element
function rt.Scale:_update_slider()
    meta.assert_isa(self, rt.Scale)
    if self._orientation == rt.Orientation.HORIZONTAL then
        local x, y = self._left:get_position()
        local width = self._left:get_width() + self._left_right:get_width() + self._right:get_width()
        self._slider:fit_into(rt.AABB(x, y, 20, 20)) -- TODO
    elseif self._orientation == rt.Orientation.VERTICAL then
        local x, y = self._top:get_position()
        local height = self._top:get_height() + self._top_bottom:get_height() + self._bottom:get_height()
        self._slider:fit_into(rt.AABB(x, y, 20, 20)) -- TODO
    end
end

--- @overload rt.Widget.size_allocate
function rt.Scale:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Scale)

    if self._orientation == rt.Orientation.HORIZONTAL then
        local h = ternary(self:get_expand_vertically(), height, self._spritesheet:get_frame_height(rt.settings.scale.slider_id))
        local left_w = self._spritesheet:get_frame_width(rt.settings.scale.rail_left_id)
        local center_w = self._spritesheet:get_frame_width(rt.settings.scale.rail_left_right_id)
        local right_w = self._spritesheet:get_frame_width(rt.settings.scale.rail_right_id)
        local w = ternary(self:get_expand_horizontally(), width, left_w + center_w + right_w)

        self._left:fit_into(rt.AABB(x, y, left_w, h))
        self._left_right:fit_into(rt.AABB(x + left_w, y, width - left_w - right_w, h))
        self._right:fit_into(rt.AABB(x + left_w + (width - left_w - right_w), y, right_w, h))

    elseif self._orientation == rt.Orientation.VERTICAL then
        local w = ternary(self:get_expand_horizontally(), width, self._spritesheet:get_frame_width(rt.settings.scale.slider_id))
        local top_h = self._spritesheet:get_frame_height(rt.settings.scale.rail_top_id)
        local center_h = self._spritesheet:get_frame_height(rt.settings.scale.rail_top_bottom_id)
        local bottom_h = self._spritesheet:get_frame_height(rt.settings.scale.rail_bottom_id)
        local h = ternary(self:get_expand_vertically(), height, top_h + center_h + bottom_h)

        self._top:fit_into(rt.AABB(x, y, w, top_h))
        self._top_bottom:fit_into(rt.AABB(x, y + top_h, w, width - top_h - bottom_h))
        self._bottom:fit_into(rt.AABB(x, y + top_h + (width - top_h - bottom_h)), w, bottom_h)
    end

    self:_update_slider()
end

--- @overload rt.Widget.measure
function rt.Scale:measure()
    meta.assert_isa(self, rt.Scale)
   
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
