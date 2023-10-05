--- @class rt.GridLayout
rt.GridLayout = meta.new_type("GridLayout", function()
    return meta.new(rt.GridLayout, {
        _children = rt.Queue(),
        _orientation = rt.Orientation.VERTICAL,
        _min_n_rows = 0,
        _min_n_cols = 0,
        _row_spacing = 0,
        _column_spacing = 0
    }, rt.Drawable, rt.Widget)
end)

--- @overlay rt.Widget.size_allocate
function rt.GridLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.GridLayout)

    local tile_w = 0
    local tile_h = 0

    for _, child in pairs(self._children) do
        local w, h = child:measure()
        tile_w = math.max(tile_w, w)
        tile_h = math.max(tile_h, h)
    end

    local n_rows = math.floor(width / (tile_w + self._row_spacing))
    tile_w = width / n_rows

    local n_cols = math.floor(height / (tile_h + self._column_spacing))
    tile_h = height / n_cols

    if self._orientation == rt.Orientation.HORIZONTAL then
        local tile_x = x + self._row_spacing
        local tile_y = y + self._column_spacing

        local row_i = 0
        local col_i = 0
        for _, child in pairs(self._children) do

            child:fit_into(rt.AABB(
                x + (tile_w * row_i) + 0.5 * self._row_spacing,
                y + (tile_h * col_i) + 0.5 * self._column_spacing,
                tile_w - 0.5 * self._row_spacing,
                tile_h - 0.5 * self._column_spacing
            ))
            row_i = row_i + 1
            if row_i >= n_rows then
                col_i = col_i + 1
                row_i = 0
            end
        end
    elseif self._orientation == rt.Orientation.VERTICAL then
        local tile_x = x + self._row_spacing
        local tile_y = y + self._column_spacing

        local row_i = 0
        local col_i = 0
        for _, child in pairs(self._children) do

            child:fit_into(rt.AABB(
                    x + (tile_w * row_i) + 0.5 * self._row_spacing,
                    y + (tile_h * col_i) + 0.5 * self._column_spacing,
                    tile_w - 0.5 * self._row_spacing,
                    tile_h - 0.5 * self._column_spacing
            ))
            col_i = col_i + 1
            if col_i >= n_cols then
                row_i = row_i + 1
                col_i = 0
            end
        end
    end
end

--- @overload rt.Widget.measure
function rt.GridLayout:measure()
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
function rt.GridLayout:draw()
    meta.assert_isa(self, rt.GridLayout)
    if not self:get_is_visible() then return end
    for _, child in pairs(self._children) do
        child:draw()
    end
end

--- @brief
function rt.GridLayout:set_children(children)
    meta.assert_isa(self, rt.GridLayout)
    self._children:clear()
    for _, child in pairs(children) do
        meta.assert_isa(child, rt.Widget)
        self._children:push_back(child)
    end
    self:reformat()
end

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

--- @brief TODO
function rt.GridLayout:set_row_spacing(x)
    meta.assert_isa(self, rt.GridLayout)
    meta.assert_number(x)
    self._row_spacing = x
end

--- @brief
function rt.GridLayout:get_row_spacing()
    meta.assert_isa(self, rt.GridLayout)
    return self._row_spacing
end

--- @brief TODO
function rt.GridLayout:set_column_spacing(x)
    meta.assert_isa(self, rt.GridLayout)
    meta.assert_number(x)
    self._column_spacing = x
end

--- @brief
function rt.GridLayout:get_column_spacing()
    meta.assert_isa(self, rt.GridLayout)
    return self._column_spacing
end

