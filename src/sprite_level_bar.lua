rt.settings.sprite_level_bar = {}
rt.settings.sprite_level_bar.rail_left_id = "rail_left"
rt.settings.sprite_level_bar.rail_left_right_id = "rail_horizontal"
rt.settings.sprite_level_bar.rail_right_id = "rail_right"
rt.settings.sprite_level_bar.rail_top_id = "rail_top"
rt.settings.sprite_level_bar.rail_top_bottom_id = "rail_vertical"
rt.settings.sprite_level_bar.rail_bottom_id = "rail_bottom"
rt.settings.sprite_level_bar.overlay_left_id = "overlay_left"
rt.settings.sprite_level_bar.overlay_left_right_id = "overlay_horizontal"
rt.settings.sprite_level_bar.overlay_right_id = "overlay_right"
rt.settings.sprite_level_bar.overlay_top_id = "overlay_top"
rt.settings.sprite_level_bar.overlay_top_bottom_id = "overlay_vertical"
rt.settings.sprite_level_bar.overlay_bottom_id = "overlay_bottom"

--- @class rt.SpriteLevelbar
rt.SpriteLevelbar = meta.new_type("SpriteLevelbar", function(spritesheet, lower, upper, value, orientation, use_overlay)


    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end

    if meta.is_nil(orientation) then
        orientation = rt.Orientation.HORIZONTAL
    end


    if meta.is_nil(use_overlay) then
        use_overlay = true
    end


    local use_overlay = true
    for id in range(
        rt.settings.sprite_level_bar.overlay_left_id,
        rt.settings.sprite_level_bar.overlay_left_right_id,
        rt.settings.sprite_level_bar.overlay_right_id,
        rt.settings.sprite_level_bar.overlay_top_id,
        rt.settings.sprite_level_bar.overlay_top_bottom_id,
        rt.settings.sprite_level_bar.overlay_bottom_id
    ) do
        if not spritesheet:has_animation(id) then
            use_overlay = false
            rt.log("In rt.SpriteLevelbar: Spritesheet `" .. spritesheet.name .. "` is missing bar overlay animations, disabling overlay...")
            break
        end
    end

    local out = meta.new(rt.SpriteLevelbar, {
        _spritesheet = spritesheet,
        _rail_left = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_left_id),
        _rail_left_right = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_left_right_id),
        _rail_right = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_right_id),
        _rail_top = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_top_id),
        _rail_top_bottom = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_top_bottom_id),
        _rail_bottom = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.rail_bottom_id),
        _overlay_left = {},
        _overlay_left_right = {},
        _overlay_right = {},
        _overlay_top = {},
        _overlay_top_bottom = {},
        _overlay_bottom = {},
        _bar = rt.VertexRectangle(0, 0, 0, 0),
        _use_overlay = use_overlay,
        _lower = lower,
        _upper = upper,
        _value = value,
        _orientation = orientation
    }, rt.Drawable, rt.Widget)

    if use_overlay then
        out._overlay_left = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_left_id)
        out._overlay_left_right = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_left_right_id)
        out._overlay_right = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_right_id)
        out._overlay_top = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_top_id)
        out._overlay_top_bottom = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_top_bottom_id)
        out._overlay_bottom = rt.Sprite(spritesheet, rt.settings.sprite_level_bar.overlay_bottom_id)
    end

    out._bar:set_color(rt.Palette.TRUE_MAGENTA)
    return out
end)

--- @overload rt.Drawable.draw
function rt.SpriteLevelbar:draw()

    if not self:get_is_visible() then return end

    if self._orientation == rt.Orientation.HORIZONTAL then
        self._rail_left_right:draw()
        self._rail_left:draw()
        self._rail_right:draw()

        self._bar:draw()

        if self._use_overlay then
            self._overlay_left_right:draw()
            self._overlay_left:draw()
            self._overlay_right:draw()
        end

    elseif self._orientation == rt.Orientation.VERTICAL then
        self._rail_top_bottom:draw()
        self._rail_top:draw()
        self._rail_bottom:draw()

        self._bar:draw()

        if self._use_overlay then
            self._overlay_top_bottom:draw()
            self._overlay_top:draw()
            self._overlay_bottom:draw()
        end
    end
end

--- @brief [internal] reposition slider element
function rt.SpriteLevelbar:_update_bar()


    local frame_w, frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.overlay_left_id)
    local x, y, bar_w, bar_h
    if self._orientation == rt.Orientation.HORIZONTAL then
        x, y = self._rail_left:get_position()
        local w = self._rail_right:get_position() + self._rail_right:get_width() - x
        local h = self._rail_left_right:get_height()
        bar_h = ternary(self:get_expand_vertically(), self._rail_left_right:get_height(), frame_h)
        bar_w = ((self._value - self._lower) / (self._upper - self._lower)) * w
    elseif self._orientation == rt.Orientation.VERTICAL then
        x, y = self._rail_top:get_position()
        local h = ({self._rail_bottom:get_position()})[2] + self._rail_bottom:get_height() - x

        bar_w = ternary(self:get_expand_horizontally(), self._rail_top_bottom:get_width(), frame_w)
        bar_h = ((self._value - self._lower) / (self._upper - self._lower)) * h
    end

    self._bar:resize(x, y, bar_w, bar_h)
end

--- @overload rt.Widget.size_allocate
function rt.SpriteLevelbar:size_allocate(x, y, width, height)


    local left_m, right_m, top_m, bottom_m = self:get_margin_left(), self:get_margin_right(), self:get_margin_top(), self:get_margin_bottom()

    if self._orientation == rt.Orientation.HORIZONTAL then
        local left_frame_w, left_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_left_id)
        local right_frame_w, right_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_right_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_left_right_id)

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

        local left_aabb = rt.AABB(x + left_m, y + 0.5 * height - 0.5 * left_h, left_w, left_h)
        local center_aabb = rt.AABB(x + left_m + left_w, y + 0.5 * height - 0.5 * center_h, center_w, center_h)
        local right_aabb = rt.AABB(x + width - right_m - right_w, y + 0.5 * height - 0.5 * right_h, right_w, right_h)
        self._rail_left:fit_into(left_aabb)
        self._rail_left_right:fit_into(center_aabb)
        self._rail_right:fit_into(right_aabb)

        if self._use_overlay then
            self._overlay_left:fit_into(left_aabb)
            self._overlay_left_right:fit_into(center_aabb)
            self._overlay_right:fit_into(right_aabb)
        end

    elseif self._orientation == rt.Orientation.VERTICAL then
        local top_frame_w, top_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_top_id)
        local center_frame_w, center_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_top_bottom_id)
        local bottom_frame_w, bottom_frame_h = self._spritesheet:get_frame_size(rt.settings.sprite_level_bar.rail_bottom_id)

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

        local top_aabb = rt.AABB(x + 0.5 * width - 0.5 * top_w, y + top_m, top_w, top_h)
        local center_aabb = rt.AABB(x + 0.5 * width - 0.5 * center_w, y + top_m + top_h, center_w, center_h)
        local bottom_aabb = rt.AABB(x + 0.5 * width - 0.5 * bottom_w, y + height - bottom_m - bottom_h, bottom_w, bottom_h)
        self._rail_top:fit_into(top_aabb)
        self._rail_top_bottom:fit_into(center_aabb)
        self._rail_bottom:fit_into(bottom_aabb)

        if self._use_overlay then
            self._overlay_top:fit_into(top_aabb)
            self._overlay_top_bottom:fit_into(center_aabb)
            self._overlay_bottom:fit_into(bottom_aabb)
        end
    end

    self:_update_bar()
end

--- @overload rt.Widget.realize
function rt.SpriteLevelbar:realize()


    self._rail_left:realize()
    self._rail_left_right:realize()
    self._rail_right:realize()
    self._rail_top:realize()
    self._rail_top_bottom:realize()
    self._rail_bottom:realize()

    if self._use_overlay then
        self._overlay_left:realize()
        self._overlay_left_right:realize()
        self._overlay_right:realize()
        self._overlay_top:realize()
        self._overlay_top_bottom:realize()
        self._overlay_bottom:realize()
    end

    self:_update_bar()
    rt.Widget.realize(self)
end

--- @brief set level_bar value
--- @param value Number
function rt.SpriteLevelbar:set_value(value)



    self._value = clamp(value, self._lower, self._upper)
    self:_update_bar()
end

--- @brief get level_bar value
--- @return Number
function rt.SpriteLevelbar:get_value()

    return self._value
end

--- @brief set orientation
--- @param orientation rt.Orientation
function rt.SpriteLevelbar:set_orientation(orientation)


    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.SpriteLevelbar:get_orientation()

    return self._orientation
end

--- @brief set color
--- @param color rt.RGBA (or rt.HSVA)
function rt.SpriteLevelbar:set_color(color)

    if not (meta.is_rgba(color) or meta.is_hsva(color)) then
        rt.error("In rt.SpriteLevelbar:set_color: Expected color, got `" .. meta.typeof(color) .. "`")
    end
    self._bar:set_color(color)
end

--- @brief [internal] test
function rt.test.sprite_level_bar()
    error("TODO")
end
