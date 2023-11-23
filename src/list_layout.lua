--- @class rt.ListLayout
--- @param orientation rt.Orientation
--- @varag rt.Widget
rt.ListLayout = meta.new_type("ListLayout", function(orientation, ...)
    if meta.is_nil(orientation) then
        orientation = rt.Orientation.HORIZONTAL
    end
    meta.assert_enum(orientation, rt.Orientation)

    local out = meta.new(rt.ListLayout, {
        _children = rt.List(),
        _orientation = orientation,
        _spacing = 0,
    }, rt.Drawable, rt.Widget)

    for _, x in pairs({...}) do
        out:push_back(x)
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
    local n_children = self._children:size()
    if self._orientation == rt.Orientation.HORIZONTAL then

        -- measure final size of all children after expansion
        local child_w = 0
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            if child:get_expand_horizontally() then
                w = math.max(width / n_children, w)
            end
            child_w = child_w + w
        end

        local child_x = x + 0.5 * width - 0.5 * child_w
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            if child:get_expand_horizontally() then
                w = math.max((width - (n_children - 1) * self._spacing) / n_children, w)
            end

            child:fit_into(rt.AABB(
                child_x, y,
                w, ternary(self:get_expand_vertically(), height, h))
            )
            child_x = child_x + w + self._spacing
        end
    else
        local child_h = 0
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            if child:get_expand_vertically() then
                h = math.max(height / n_children, h)
            end
            child_h = child_h + h
        end

        local child_y = y + 0.5 * height - 0.5 * child_h
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            if child:get_expand_vertically() then
                h = math.max((height - (n_children - 1) * self._spacing)  / n_children, h)
            end
            child:fit_into(rt.AABB(x, child_y, width, h))
            child_y = child_y + h + self._spacing
        end
    end
end

--- @overload rt.Widget.measure
function rt.ListLayout:measure()
    local w_sum = 0
    local w_max = NEGATIVE_INFINITY
    local h_sum = 0
    local h_max = NEGATIVE_INFINITY

    for _, child in pairs(self._children) do
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

--- @overload rt.Widget.realize
function rt.ListLayout:realize()
    meta.assert_isa(self, rt.ListLayout)
    self._realized = true
    for _, child in pairs(self._children) do
        child:realize()
    end
end

--- @brief replace all children
--- @param children Table<rt.Widget>
function rt.ListLayout:set_children(children)
    meta.assert_isa(self, rt.ListLayout)
    for child in pairs(self._children) do
        child:set_parent(nil)
    end
    self._children:clear()
    for _, child in pairs(children) do
        meta.assert_isa(child, rt.Widget)
        child:set_parent(self)
        self._children:push_back(child)
        if self:get_is_realized() then child:realize() end
    end
    self:reformat()
end

--- @brief append child
--- @param child rt.Widget
function rt.ListLayout:push_back(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._children:push_back(child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief prepend child
--- @param child rt.Widget
function rt.ListLayout:push_front(child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._children:push_back(child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief remove first child
--- @return rt.Widget
function rt.ListLayout:pop_front()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_front()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief remove last child
--- @return rt.Widget
function rt.ListLayout:pop_back()
    meta.assert_isa(self, rt.ListLayout)
    local out = self._children:pop_back()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief insert child at position
--- @param index Number 1-based
--- @param child rt.Widget
function rt.ListLayout:insert(index, child)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_isa(child, rt.Widget)
    meta.assert_number(index)

    child:set_parent(self)
    self._children:insert(index, child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
    self:reformat()
end

--- @brief remove child at position
--- @param index Number 1-based
function rt.ListLayout:erase(index)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_number(index)

    local child = self._children:erase(index)
    child:set_parent(nil)
    self:reformat()
end

--- @brief set orientation
--- @param orientation rt.Orientation
function rt.ListLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.ListLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.ListLayout:get_orientation()
    meta.assert_isa(self, rt.ListLayout)
    return self._orientation
end

--- @brief set spacing
function rt.ListLayout:set_spacing(spacing)
    meta.assert_isa(self, rt.ListLayout)
    meta.assert_number(spacing)
    spacing = clamp(spacing, 0)
    if self._spacing ~= spacing then
        self._spacing = spacing
        self:reformat()
    end
end

--- @brief get spacing
function rt.ListLayout:get_spacing()
    meta.assert_isa(self, rt.ListLayout)
    return self._spacing
end

--- @brief test ListLayout
function rt.test.list_layout()
    error("TODO")
end
