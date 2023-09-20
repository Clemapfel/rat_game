--- @class rt.GridLayout
rt.GridLayout = meta.new_type("GridLayout", function()
    local out = meta.new(rt.GridLayout, {
        _children = rt.Queue(),
        _orientation = rt.Orientation.VERTICAL,
        _min_n_rows = 0,
        _min_n_cols = 0
    }, rt.Drawable, rt.Widget)
end)

--- @brief
function rt.GridLayout:push_back(child)
    meta.assert_isa(self, rt.GridLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
function rt.GridLayout:push_front(child)
    meta.assert_isa(self, rt.GridLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
--- @return rt.Widget
function rt.GridLayout:pop_front()
    meta.assert_isa(self, rt.GridLayout)
    local out = self._children:pop_front()
    self:reformat()
    return out
end

--- @brief
--- @return rt.Widget
function rt.GridLayout:pop_back()
    meta.assert_isa(self, rt.GridLayout)
    local out = self._children:pop_back()
    self:reformat()
    return out
end

--- @brief set orientation, causes reformat
--- @param orientation rt.Orientation
function rt.GridLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.GridLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.GridLayout:get_orientation()
    meta.assert_isa(self, rt.GridLayout)
    return self._orientation
end
