--- @class ListLayout
rt.ListLayout = meta.new_type("ListLayout", function(orientation, ...)
    if meta.is_nil(orientation) then
        orientation = rt.Orientation.VERTICAL
    end
    meta.assert_enum(orientation, rt.Orientation)

    local out = meta.new(rt.ListLayout, {
        _children = rt.Queue(),
        _orientation = rt.Orientation
    }, rt.Drawable, rt.Widget)

    for _, x in pairs({...}) do
        out:push_bacK(x)
    end
    return out
end)
rt.BoxLayout = rt.ListLayout

--- @overload rt.Drawable.draw
function rt.ListLayout:draw()
    meta.assert_isa(self, rt.ListLayout)
    if not self:get_is_visible() then return end
    for _, child in pairs(self._children) do
        child:draw()
    end
end

--- @overlay rt.Widget.size_allocate
function rt.ListLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.ListLayout)
    self._bounds = rt.AABB(x, y, width, height)
    if self:get_orientation() == rt.Orientation.HORIZONTAL then
        if self:get_expand_horizontally() then
            local width_sum = 0
            for _, child in pairs(self._children) do
                local w, _ = child:measure()
                if w > 1 then
                    width_sum = width_sum + w
                end
            end

            local target_w = (width - width_sum) / #self._children
            for _, child in pairs(self._children) do
                local measure_w, _ = child:measure()
                local final_w = math.max(measure_w, target_w)
                child:fit_into(rt.AABB(x, y, final_w, height))
                x = x + final_w
            end
        else
            for _, child in pairs(self._children) do
                local w, h = child:measure()
                child:fit_into(rt.AABB(x, y, w, height))
                x = x + w
            end
        end
    else
        if self:get_expand_vertically() then
            local height_sum = 0
            for _, child in pairs(self._children) do
                local _, h = child:measure()
                if h > 1 then
                    height_sum = height_sum + h
                end
            end

            local target_h = (height - height_sum) / #self._children
            for _, child in pairs(self._children) do
                local _, measure_h = child:measure()
                local final_h = math.max(measure_h, target_h)
                child:fit_into(rt.AABB(x, y, width, final_h))
                y = y + final_h
            end
        else
            for _, child in pairs(self._children) do
                local w, h = child:measure()
                child:fit_into(rt.AABB(x, y, width, h))
                y = y + h
            end
        end
    end
end

--- @overload rt.Widget.measure
function rt.ListLayout:measure()
    local w_sum = 0
    local w_max = NEGATIVE_INFINITY
    local h_sum = 0
    local h_max = NEGATIVE_INFINITY

    for _, child in pairs(children) do
        local w, h = child:measure()
        w_sum = w_sum + w
        h_sum = h_sum + h
        w_max = math.max(w_max, w)
        h_max = math.max(h_max, h)
    end

    if self:get_orientation() == rt.Orientation.HORIZONTAL then
        return w_sum, h_max
    else
        return w_max, h_sum
    end
end

--- @brief
function rt.ListLayout:set_children(children)
    meta.assert_isa(self, rt.GridLayout)
    for child in pairs(self._children) do
        child:set_parent(nil)
    end
    self._children:clear()
    for _, child in pairs(children) do
        meta.assert_isa(child, rt.Widget)
        child:set_parent(self)
        self._children:push_back(child)
    end
    self:reformat()
end

--- @brief
function rt.ListLayout:push_back(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
function rt.ListLayout:push_front(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
--- @return rt.Widget
function rt.ListLayout:pop_front()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_front()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief
--- @return rt.Widget
function rt.ListLayout:pop_back()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_back()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief
function rt.ListLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.ListLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief
--- @return rt.Orientation
function rt.ListLayout:get_orientation()
    meta.assert_isa(self, rt.ListLayout)
    return self._orientation
end

--- @brief test ListLayout
function rt.test.list_layout()
    -- TODO
end
rt.test.list_layout()