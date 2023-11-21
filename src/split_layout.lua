--- @class rt.SplitLayout
rt.SplitLayout = meta.new_type("SplitLayout", function()
    local out = meta.new(rt.SplitLayout, {
        _start_child = {},
        _end_child = {},
        _orientation = rt.Orientation.HORIZONTAL,
        _ratio = 0.5 -- start to end child
    }, rt.Drawable, rt.Widget)
    return out
end)

--- @overload rt.Drawable.draw
function rt.SplitLayout:draw()
    meta.assert_isa(self, rt.SplitLayout)
    self._start_child:draw()
    self._end_child:draw()
end

--- @overload rt.Widget.size_allocate
function rt.SplitLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.SplitLayout)
    local has_start = meta.isa(self._start_child, rt.Widget)
    local has_end = meta.isa(self._end_child, rt.Widget)
    if has_start and not has_end then
        self._start_child:fit_into(x, y, width, height)
    elseif not has_start and has_end then
        self._end_child:fit_into(x, y, width, height)
    else
        if self._orientation == rt.Orientation.HORIZONTAL then
            local left_width = self._ratio * width
            local right_width = (1 - self._ratio) * width
            self._start_child:fit_into(rt.AABB(x, y, left_width, height))
            self._end_child:fit_into(rt.AABB(x + left_width, y, right_width, height))
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
    meta.assert_isa(self, rt.SplitLayout)
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
    meta.assert_isa(self, rt.SplitLayout)
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
    meta.assert_isa(self, rt.SplitLayout)
    meta.assert_isa(child, rt.Widget)

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
    meta.assert_isa(self, rt.SplitLayout)
    return self._start_child
end

--- @brief remove first child
function rt.SplitLayout:remove_start_child()
    meta.assert_isa(self, rt.SplitLayout)
    if meta.isa(self._start_child, rt.Widget) then
        self._start_child:set_parent(nil)
        self._start_child = nil
    end
end

--- @brief set last child
--- @param child rt.Widget
function rt.SplitLayout:set_end_child(child)
    meta.assert_isa(self, rt.SplitLayout)
    meta.assert_isa(child, rt.Widget)

    self:remove_end_child()
    child:set_parent(self)
    self._end_child = child
    if self:get_is_realized() then child:realize() end
    self:reformat()
end

--- @brief get last child
--- @return rt.Widget
function rt.SplitLayout:get_end_child()
    meta.assert_isa(self, rt.SplitLayout)
    return self._end_child
end

--- @brief remove last child
function rt.SplitLayout:remove_end_child()
    meta.assert_isa(self, rt.SplitLayout)
    if meta.isa(self._end_child, rt.Widget) then
        self._end_child:set_parent(nil)
        self._end_child = nil
    end
end

--- @brief set ratio between first and last child, width if horizontal, height if vertical
--- @param ratio Number
function rt.SplitLayout:set_ratio(ratio)
    meta.assert_isa(self, rt.SplitLayout)
    meta.assert_number(ratio)
    if ratio < 0 or ratio > 1 then
        rt.error("In rt.SplitLayout.set_ratio: ratio `" .. tostring(ratio) .. "` has to be inside [0, 1]")
    end
    self._ratio = ratio
    self:reformat()
end

--- @brief get ratio
--- @return Number
function rt.SplitLayout:get_ratio()
    meta.assert_isa(self, rt.SplitLayout)
    return self._ratio
end

--- @brief set orientation, causes reformat
--- @param orientation rt.Orientation
function rt.SplitLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.SplitLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.SplitLayout:get_orientation()
    meta.assert_isa(self, rt.SplitLayout)
    return self._orientation
end

--- @brief test SplitLayout
function rt.test.split_layout()
    error("TODO")
end
