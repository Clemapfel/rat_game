--- @class rt.SplitLayout
rt.SplitLayout = meta.new_type("SplitLayout", function()
    local out = meta.new(rt.SplitLayout, {
        _start_child = nil,
        _end_child = nil,
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
    if meta.is_nil(self._start_child) and meta.is_nil(self._end_child) then
        -- noop
    elseif not meta.is_nil(self._start_child) and meta.is_nil(self._end_child) then
        self._start_child:fit_into(rt.AABB(x, y, width, height))
    elseif meta.is_nil(self._start_child) and not meta.is_nil(self._end_child) then
        self._end_child:fit_into(rt.AABB(x, y, width, height))
    else
        if self:get_orientation() == rt.Orientation.HORIZONTAL then
            local start_width = self._ratio * width
            self._start_child:fit_into(rt.AABB(x, y, start_width, height))
            self._end_child:fit_into(rt.AABB(x + start_width, y, width - start_width, height))
        elseif self:get_orientation() == rt.Orientation.VERTICAL then
            local start_height = self._ratio * height
            self._start_child:fit_into(rt.AABB(x, y, width, start_height))
            self._end_child:fit_into(rt.AABB(x, y + start_height, width, height - start_height))
        end
    end
end

--- @overload rt.Widget.measure
function rt.SplitLayout:measure()
    if not meta.is_nil(self._start_child) and not meta.is_nil(self._end_child) then
        local x, y = self._start_child:get_position()
        local start_w, start_h = self._start_child:get_size()
        local end_w, end_h = self._end_child:get_size()
        return rt.AABB(x, y, start_w + end_w, start_h + end_h)
    elseif not meta.is_nil(self._start_child) then
        return self._start_child:measure()
    elseif notmeta.is_nil(self._end_child) then
        return self._end_child:measure()
    else
        return rt.AABB(0, 0, 0, 0)
    end
end

--- @brief
function rt.SplitLayout:set_start_child(child)
    meta.assert_isa(self, rt.SplitLayout)
    self._start_child = child
    self:reformat()
end

--- @brief
function rt.SplitLayout:get_start_child()
    meta.assert_isa(self, rt.SplitLayout)
    return self._start_child
end

--- @brief
function rt.SplitLayout:set_end_child(child)
    meta.assert_isa(self, rt.SplitLayout)
    self._end_child = child
    self:reformat()
end

--- @brief
function rt.SplitLayout:get_end_child()
    meta.assert_isa(self, rt.SplitLayout)
    return self._end_child
end

--- @brief
function rt.SplitLayout:set_ratio(ratio)
    meta.assert_isa(self, rt.SplitLayout)
    meta.assert_number(ratio)
    if ratio < 0 or ratio > 1 then
        error("[rt] In rt.SplitLayout.set_ratio: ratio `" .. tostring(ratio) .. "` has to be inside [0, 1]")
    end
    self._ratio = ratio
    self:reformat()
end

--- @brief
function rt.SplitLayout:get_ratio()
    meta.assert_isa(self, rt.SplitLayout)
    return self._ratio
end

--- @brief
function rt.SplitLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.SplitLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief
--- @return rt.Orientation
function rt.SplitLayout:get_orientation()
    meta.assert_isa(self, rt.SplitLayout)
    return self._orientation
end


--- @brief test SplitLayout
function rt.test.split_layout()
    -- TODO
end
rt.test.split_layout()