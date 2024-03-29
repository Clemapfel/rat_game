--- @class rt.GridLayout
rt.GridLayout = meta.new_type("GridLayout", function()
    return meta.new(rt.GridLayout, {
        _children = rt.List(),
        _orientation = rt.Orientation.VERTICAL,
        _min_n_cols = 0,
        _max_n_cols = POSITIVE_INFINITY,
        _min_n_rows = 0,
        _max_n_rows = POSITIVE_INFINITY,
        _row_spacing = 0,
        _column_spacing = 0
    }, rt.Drawable, rt.Widget)
end)

--- @overlay rt.Widget.size_allocate
function rt.GridLayout:size_allocate(x, y, width, height)
    local tile_w = 0
    local tile_h = 0
    for _, child in pairs(self._children) do
        local w, h = child:measure()
        tile_w = math.max(tile_w, w)
        tile_h = math.max(tile_h, h)
    end

    if self._max_n_rows * self._max_n_cols < self._children:size() then
        rt.warning("In rt.GridLayout:size_allocate: Requested grid layout to have a maximum size of `" .. tostring(self._max_n_rows) .. " * " .. tostring(self._max_n_cols) .. " = " .. tostring(self._max_n_rows * self._max_n_cols) .. "`, but it has `" .. tostring(self._children:size()) .. "` elements.")
    end

    if self._orientation == rt.Orientation.HORIZONTAL then

        local n_rows = math.floor(width / (tile_w + self._row_spacing))
        n_rows = clamp(n_rows, self._min_n_rows, self._max_n_rows)
        tile_w = math.max(tile_w, width / n_rows)

        local n_cols = math.floor(height / (tile_h + self._column_spacing))
        n_cols = clamp(n_cols, self._min_n_cols, self._max_n_cols)
        tile_h = math.max(tile_h, height / n_cols)

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

        local n_rows = math.floor(width / (tile_w + self._row_spacing))
        n_rows = clamp(n_rows, self._min_n_rows, self._max_n_rows)
        tile_w = math.max(tile_w, width / n_rows)

        local n_cols = math.floor(height / (tile_h + self._column_spacing))
        n_cols = clamp(n_cols, self._min_n_cols, self._max_n_cols)
        tile_h = math.max(tile_h, height / n_cols)

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
    if not self:get_is_visible() then return end
    for _, child in pairs(self._children) do
        child:draw()
    end
end

--- @overload rt.Drawable.realize
function rt.GridLayout:realize()
    if self:get_is_realized() == true then return end
    self._is_realized = true
    for _, child in pairs(self._children) do
        child:realize()
    end
end

--- @brief replace children
--- @param children Table<rt.Widget>
function rt.GridLayout:set_children(children)
    for child in pairs(self._children) do
        child:set_parent(nil)
    end
    self._children:clear()
    for _, child in pairs(children) do

        child:set_parent(self)
        self._children:push_back(child)
        if self._realize then child:realize() end
    end
    self:reformat()
end

--- @brief append child
--- @param child rt.Widget
function rt.GridLayout:push_back(child)
    child:set_parent(self)
    self._children:push_back(child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief prepend child
--- @param child rt.Widget
function rt.GridLayout:push_front(child)
    child:set_parent(self)
    self._children:push_back(child)
    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief remove first child
--- @return rt.Widget
function rt.GridLayout:pop_front()
    local out = self._children:pop_front()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief remove last child
--- @return rt.Widget
function rt.GridLayout:pop_back()
    local out = self._children:pop_back()
    out:set_parent(nil)
    self:reformat()
    return out
end

--- @brief insert child at position
--- @param index Number 1-based
--- @param child rt.Widget
function rt.GridLayout:insert(index, child)
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
function rt.GridLayout:erase(index)
    local child = self._children:erase(index)
    child:set_parent(nil)
    self:reformat()
end

--- @brief set orientation, causes reformat
--- @param orientation rt.Orientation
function rt.GridLayout:set_orientation(orientation)
    if self._orientation == orientation then return end
    self._orientation = orientation
    self:reformat()
end

--- @brief get orientation
--- @return rt.Orientation
function rt.GridLayout:get_orientation()
    return self._orientation
end

--- @brief set spacing between rows
--- @param x Number px
function rt.GridLayout:set_row_spacing(x)
    if self._row_spacing ~= x then
        self._row_spacing = x
        self:reformat()
    end
end

--- @brief get spacing between rows
--- @return Number px
function rt.GridLayout:get_row_spacing()
    return self._row_spacing
end

--- @brief set spacing between columns
--- @param x Number px
function rt.GridLayout:set_column_spacing(x)
    if self._column_spacing ~= x then
        self._column_spacing = x
        self:reformat();
    end
end

--- @brief get spacing between columns
--- @param Number px
function rt.GridLayout:get_column_spacing()
    return self._column_spacing
end

--- @brief set lower bound for rows
--- @param n Number
function rt.GridLayout:set_min_n_rows(n)
    if self._min_n_rows ~= n then
        self._min_n_rows = n
        self:reformat()
    end
end

--- @brief set upper bound for rows
--- @param n Number
function rt.GridLayout:set_max_n_rows(n)
    if self._max_n_rows ~= n then
        self._max_n_rows = n
        self:reformat()
    end
end

--- @brief set lower bound for columns
--- @param n Number
function rt.GridLayout:set_min_n_columns(n)
    if self._min_n_cols ~= n then
        self._min_n_cols = n
        self:reformat()
    end
end

--- @brief set upper bound for columns
--- @param n Number
function rt.GridLayout:set_max_n_columns(n)
    if self._max_n_cols ~= n then
        self._max_n_cols = n
        self:reformat()
    end
end

