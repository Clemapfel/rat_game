--- @class ListLayout
rt.ListLayout = meta.new_type("ListLayout", function()
    return meta.new(rt.ListLayout, {
        _children = rt.Queue(),
        _orientation = rt.Orientation
    }, rt.Drawable, rt.Widget)
end)

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
        local w = width / #self._children
        for _, child in pairs(self._children) do
            child:fit_into(rt.AABB(x, y, w, height))
            x = x + w
        end
    else
        local h = height / #self._children
        for _, child in pairs(self._children) do
            child:fit_into(rt.AABB(x, y, width, h))
            y = y + h
        end
    end
end

--- @brief
function rt.ListLayout:push_back(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
function rt.ListLayout:push_front(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
--- @return rt.Widget
function rt.ListLayout:pop_front()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_front()
    self:reformat()
    return out
end

--- @brief
--- @return rt.Widget
function rt.ListLayout:pop_back()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_back()
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
