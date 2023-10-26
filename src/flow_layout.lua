--- @class rt.FlowLayout
--- @brief container that automatically redistributes it's children across as many rows/columns as necessary
rt.FlowLayout = meta.new_type("FlowLayout", function(orientation)
    if meta.is_nil(orientation) then
        orientation = rt.Orientation.VERTICAL
    end
    meta.assert_enum(orientation, rt.Orientation)

    return meta.new(rt.FlowLayout, {
        _children = rt.Queue(),
        _orientation = orientation,
        _min_n_rows = 0,
        _min_n_cols = 0,
        _row_spacing = 0,
        _column_spacing = 0
    }, rt.Drawable, rt.Widget)
end)

--- @overload rt.Widget.size_allocate
function rt.FlowLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.FlowLayout)

    local tile_w = 0
    local tile_h = 0

    for _, child in pairs(self._children) do
        local w, h = child:measure()
        tile_w = math.max(tile_w, w)
        tile_h = math.max(tile_h, h)
    end

    if self._orientation == rt.Orientation.HORIZONTAL then

        local tile_x = x + self._row_spacing
        local tile_y = y + self._column_spacing

        for _, child in pairs(self._children) do
            local child_w, child_h = child:measure()
            local offset = child_w + self._row_spacing
            if tile_x + offset >= width then
                tile_x = x + self._row_spacing
                tile_y = tile_y + tile_h + self._column_spacing
            end
            child:fit_into(rt.AABB(tile_x, tile_y, tile_w, tile_h))
            tile_x = tile_x + offset
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        local tile_x = x + self._row_spacing
        local tile_y = y + self._column_spacing

        local row_width = NEGATIVE_INFINITY
        for _, child in pairs(self._children) do
            local child_w, child_h = child:measure()
            local offset = child_h + self._column_spacing
            if tile_y + offset >= height then
                tile_y = y + self._column_spacing
                tile_x = tile_x + tile_w + self._row_spacing
                row_width = NEGATIVE_INFINITY
            end
            child:fit_into(rt.AABB(tile_x, tile_y, tile_w, tile_h))
            tile_y = tile_y + offset
            row_max = math.max(row_width, child_w)
        end
    end
end

--- @overload rt.Widget.measure
function rt.FlowLayout:measure()
    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY

    for _, child in pairs(self._children) do
        local x, y = child:get_position()
        local w, h = child:measure()
        min_x = math.min(min_x, x)
        min_y = math.min(min_y, y)
        max_x = math.max(max_x, x + w)
        max_y = math.max(max_y, y + h)
    end

    return max_x - min_x, max_y - min_y
end

--- @overload rt.Drawable.draw
function rt.FlowLayout:draw()
    meta.assert_isa(self, rt.FlowLayout)
    if not self:get_is_visible() then return end
    for _, child in pairs(self._children) do
        child:draw()
    end
end

--- @overload rt.Widget.realize
function rt.FlowLayout:realize()
    meta.assert_isa(self, rt.FlowLayout)
    if self:get_is_realized() == true then return end
    self._realized = true
    for _, child in pairs(self._children) do
        child:realize()
    end
end

--- @brief replace all children at once
--- @param children Table<rt.Widget>
function rt.FlowLayout:set_children(children)
    meta.assert_isa(self, rt.FlowLayout)
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
function rt.FlowLayout:push_back(child)
    meta.assert_isa(self, rt.FlowLayout)
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
function rt.FlowLayout:push_front(child)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._children:push_back(child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief remove first child
--- @return rt.Widget (or nil)
function rt.FlowLayout:pop_front()
    meta.assert_isa(self, rt.FlowLayout)
    local out = self._children:pop_front()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief remove last child
--- @return rt.Widget (or nil)
function rt.FlowLayout:pop_back()
    meta.assert_isa(self, rt.FlowLayout)
    local out = self._children:pop_back()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief set orientation, causes reformat
--- @param orientation rt.Orientation
function rt.FlowLayout:set_orientation(orientation)
    meta.assert_isa(self, rt.FlowLayout)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.FlowLayout:get_orientation()
    meta.assert_isa(self, rt.FlowLayout)
    return self._orientation
end

--- @brief set spacing in-between rows
--- @param x Number
function rt.FlowLayout:set_row_spacing(x)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_number(x)
    self._row_spacing = x
end

--- @brief get spacing in-between rows
--- @return Number
function rt.FlowLayout:get_row_spacing()
    meta.assert_isa(self, rt.FlowLayout)
    return self._row_spacing
end

--- @brief set spacing in-between columns
--- @param x Number
function rt.FlowLayout:set_column_spacing(x)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_number(x)
    self._column_spacing = x
end

--- @brief get spacing in-between columns
--- @return Number
function rt.FlowLayout:get_column_spacing()
    meta.assert_isa(self, rt.FlowLayout)
    return self._column_spacing
end

