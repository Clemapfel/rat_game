--- @class rt.FlowLayout
rt.FlowLayout = meta.new_type("FlowLayout", function()
    return meta.new(rt.FlowLayout, {
        _children = rt.Queue(),
        _orientation = rt.Orientation.VERTICAL,
        _min_n_rows = 0,
        _min_n_cols = 0,
        _row_spacing = 0,
        _column_spacing = 0
    }, rt.Drawable, rt.Widget)
end)

--- @overlay rt.Widget.size_allocate
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
            local offset = tile_w + self._row_spacing
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

        for _, child in pairs(self._children) do
            local offset = tile_h + self._column_spacing
            if tile_y + offset >= height then
                tile_y = y + self._column_spacing
                tile_x = tile_x + tile_w + self._row_spacing
            end
            child:fit_into(rt.AABB(tile_x, tile_y, tile_w, tile_h))
            tile_y = tile_y + offset
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

--- @brief
function rt.FlowLayout:set_children(children)
    meta.assert_isa(self, rt.FlowLayout)
    self._children:clear()
    for _, child in pairs(children) do
        meta.assert_isa(child, rt.Widget)
        self._children:push_back(child)
    end
    self:reformat()
end

--- @brief
function rt.FlowLayout:push_back(child)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
function rt.FlowLayout:push_front(child)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_isa(child, rt.Widget)
    self._children:push_back(child)
    self:reformat()
end

--- @brief
--- @return rt.Widget
function rt.FlowLayout:pop_front()
    meta.assert_isa(self, rt.FlowLayout)
    local out = self._children:pop_front()
    self:reformat()
    return out
end

--- @brief
--- @return rt.Widget
function rt.FlowLayout:pop_back()
    meta.assert_isa(self, rt.FlowLayout)
    local out = self._children:pop_back()
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

--- @brief TODO
function rt.FlowLayout:set_row_spacing(x)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_number(x)
    self._row_spacing = x
end

--- @brief
function rt.FlowLayout:get_row_spacing()
    meta.assert_isa(self, rt.FlowLayout)
    return self._row_spacing
end

--- @brief TODO
function rt.FlowLayout:set_column_spacing(x)
    meta.assert_isa(self, rt.FlowLayout)
    meta.assert_number(x)
    self._column_spacing = x
end

--- @brief
function rt.FlowLayout:get_column_spacing()
    meta.assert_isa(self, rt.FlowLayout)
    return self._column_spacing
end

