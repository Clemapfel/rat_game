rt.settings.split_layout = {
    divider_width = rt.settings.margin_unit
}

--- @class rt.SplitLayout
rt.SplitLayout = meta.new_type("SplitLayout", function()
    local out = meta.new(rt.SplitLayout, {
        _start_child = {},
        _end_child = {},
        _orientation = rt.Orientation.HORIZONTAL,
        _draw_divider = true,
        _divider_base = rt.Rectangle(0, 0, 1, 1),
        _divider_outline = rt.Rectangle(0, 0, 1, 1),
        _ratio = 0.5, -- start to end child
    }, rt.Drawable, rt.Widget)

    out._divider_base:set_color(rt.Palette.BASE)
    out._divider_outline:set_color(rt.Palette.BASE_OUTLINE)
    out._divider_outline:set_is_outline(true)

    out._divider_base:set_corner_radius(rt.settings.margin_unit)
    out._divider_outline:set_corner_radius(rt.settings.margin_unit)
    return out
end)

--- @overload rt.Drawable.draw
function rt.SplitLayout:draw()

    if not self:get_is_visible() then return end

    self._start_child:draw()
    self._end_child:draw()

    if self._draw_divider == true then
        self._divider_base:draw()
        self._divider_outline:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.SplitLayout:size_allocate(x, y, width, height)

    local has_start = meta.isa(self._start_child, rt.Widget)
    local has_end = meta.isa(self._end_child, rt.Widget)
    if has_start and not has_end then
        self._start_child:fit_into(x, y, width, height)
    elseif not has_start and has_end then
        self._end_child:fit_into(x, y, width, height)
    else
        local divider_size = rt.settings.split_layout.divider_width
        if self._orientation == rt.Orientation.HORIZONTAL then
            local left_width = self._ratio * width - 0.5 * divider_size
            local right_width = (1 - self._ratio) * width - 0.5 * divider_size
            self._start_child:fit_into(rt.AABB(x, y, left_width, height))

            local divider_area = rt.AABB(x + left_width, y, divider_size, height)
            self._divider_base:resize(divider_area)
            self._divider_outline:resize(divider_area)

            self._end_child:fit_into(rt.AABB(x + left_width + divider_size, y, right_width, height))

        else
            local top_height = self._ratio * height
            local bottom_height = (1 - self._ratio) * height
            self._start_child:fit_into(rt.AABB(x, y, width, top_height))
            self._end_child:fit_into(rt.AABB(x, y + top_height, width, bottom_height))
        end
    end
end

--- @overload rt.Widget.measure
function rt.SplitLayout:measure()

    local has_start = meta.isa(self._start_child, rt.Widget)
    local has_end = meta.isa(self._end_child, rt.Widget)
    if has_start and not has_end then
        return self._start_child:measure()
    elseif not has_start and has_end then
        return self._end_child:measure()
    else
        if self._orientation == rt.Orientation.HORIZONTAL then
            local left_w, left_h = self._start_child:measure()
            local right_w, right_h = self._start_child:measure()
            return left_w + right_w, math.max(left_h, right_h)
        else
            local top_w, top_h = self._start_child:measure()
            local bottom_w, bottom_h = self._end_child:measure()
            return math.max(top_w, bottom_w), top_h + bottom_h
        end
    end
end

--- @overload rt.Widget.realize
function rt.SplitLayout:realize()

    self._realized = true

    if meta.isa(self._start_child, rt.Widget) then
        self._start_child:realize()
    end

    if meta.isa(self._end_child, rt.Widget) then
        self._end_child:realize()
    end
end

--- @brief set first child
--- @param child rt.Widget
function rt.SplitLayout:set_start_child(child)



    self:remove_start_child()
    child:set_parent(self)
    self._start_child = child
    if self:get_is_realized() then child:realize() end
    self:reformat()
end

--- @brief set last child
--- @param child rt.Widget
--- @return rt.Widget
function rt.SplitLayout:get_start_child()

    return self._start_child
end

--- @brief remove first child
function rt.SplitLayout:remove_start_child()

    if meta.isa(self._start_child, rt.Widget) then
        self._start_child:set_parent(nil)
        self._start_child = nil
    end
end

--- @brief set last child
--- @param child rt.Widget
function rt.SplitLayout:set_end_child(child)



    self:remove_end_child()
    child:set_parent(self)
    self._end_child = child
    if self:get_is_realized() then child:realize() end
    self:reformat()
end

--- @brief get last child
--- @return rt.Widget
function rt.SplitLayout:get_end_child()

    return self._end_child
end

--- @brief remove last child
function rt.SplitLayout:remove_end_child()

    if meta.isa(self._end_child, rt.Widget) then
        self._end_child:set_parent(nil)
        self._end_child = nil
    end
end

--- @brief set ratio between first and last child, width if horizontal, height if vertical
--- @param ratio Number
function rt.SplitLayout:set_ratio(ratio)


    if ratio < 0 or ratio > 1 then
        rt.error("In rt.SplitLayout.set_ratio: ratio `" .. tostring(ratio) .. "` has to be inside [0, 1]")
    end
    self._ratio = ratio
    self:reformat()
end

--- @brief get ratio
--- @return Number
function rt.SplitLayout:get_ratio()

    return self._ratio
end

--- @brief set orientation, causes reformat
--- @param orientation rt.Orientation
function rt.SplitLayout:set_orientation(orientation)

    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.SplitLayout:get_orientation()

    return self._orientation
end

--- @brief test SplitLayout
function rt.test.split_layout()
    error("TODO")
end
