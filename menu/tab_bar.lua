--- @class mn.TabBar
mn.TabBar = meta.new_type("TabBar", rt.Widget, function()
    return meta.new(mn.TabBar, {
        _items = {},
        _n_items = 0,
        _selected_item_i = 0,
        _n_post_aligned_items = 1,
        _orientation = rt.Orientation.HORIZONTAL,
        _final_w = 1,
        _final_h = 1,
        _selection_nodes = {}, -- List<rt.SelectionGraphNode>
    })
end)

--- @brief
function mn.TabBar:push(widget)
    local to_insert = {
        widget = widget,
        stencil = rt.Rectangle(0, 0, 1, 1),
        frame = rt.Frame(),
        base = rt.Spacer(),
        is_selected = false
    }

    to_insert.frame:set_child(to_insert.base)
    to_insert.stencil:set_corner_radius(rt.settings.frame.corner_radius)

    if self._is_realized == true then
        for element in range(to_insert.widget, to_insert.frame) do
            element:realize()
        end
    end

    table.insert(self._items, to_insert)
    self._n_items = self._n_items + 1
    if self._is_realized then self:reformat() end
end

--- @override
function mn.TabBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for item in values(self._items) do
        item.widget:realize()
        item.frame:realize()
    end
end

--- @override
function mn.TabBar:size_allocate(x, y, width, height)
    self._selection_nodes = {}

    local m = rt.settings.margin_unit
    local min_x, max_x, min_y, max_y = POSITIVE_INFINITY, NEGATIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY
    local n_post_aligned_items = clamp(self._n_post_aligned_items, 0, self._n_items)
    local item_w, item_h, item_m
    local thickness = rt.settings.frame.thickness
    if self._orientation == rt.Orientation.HORIZONTAL then
        item_h = height
        item_w = item_h
        item_m = math.min(m, (width - 2 * m - item_w - (self._n_items - n_post_aligned_items) * item_w) / (self._n_items + 1))
    else
        item_w = width
        item_h = item_w
        item_m = math.min(m, (height - 2 * m - item_h - (self._n_items - n_post_aligned_items) * item_h) / (self._n_items + 1))
    end

    local start_x, start_y
    if self._orientation == rt.Orientation.HORIZONTAL then
        start_x = x
        start_y = y
    else
        start_x = x
        start_y = y
    end

    local size_allocate_item = function(item, current_x, current_y)
        local frame_thickness = item.frame:get_thickness() + 2
        item.stencil:resize(
            current_x + frame_thickness,
            current_y + frame_thickness,
            item_w - 2 * frame_thickness,
            item_h - 2 * frame_thickness
        )
        item.frame:fit_into(current_x, current_y, item_w, item_h)

        local widget_w, widget_h = item.widget:measure()
        item.widget:fit_into(
            current_x + 0.5 * item_w - 0.5 * widget_w,
            current_y + 0.5 * item_h - 0.5 * widget_h,
            widget_w,
            widget_h
        )

        min_x = math.min(min_x, current_x)
        max_x = math.max(max_x, current_x + item_w)
        min_y = math.min(min_y, current_y)
        max_y = math.max(max_y, current_y + item_h)

        if self._orientation == rt.Orientation.HORIZONTAL then
            current_x = current_x + item_w + item_m
        else
            current_y = current_y + item_h + item_m
        end
    end

    local current_x, current_y = start_x, start_y
    local n_items = self._n_items
    for item_i = 1, self._n_items - n_post_aligned_items do
        local item = self._items[item_i]
        size_allocate_item(item, current_x, current_y)

        local node = rt.SelectionGraphNode()
        node:set_bounds(current_x, current_y, item_w, item_h)
        self._selection_nodes[item_i] = node

        if self._orientation == rt.Orientation.HORIZONTAL then
            current_x = current_x + item_w + item_m
        else
            current_y = current_y + item_h + item_m
        end
    end

    if self._orientation == rt.Orientation.HORIZONTAL then
        current_x = start_x + width - item_w - (start_x - x)
        current_y = start_y
    else
        current_x = start_x
        current_y = start_y + height - item_h - (start_y - y)
    end

    for item_i = self._n_items, self._n_items - n_post_aligned_items + 1, -1 do
        local item = self._items[item_i]
        size_allocate_item(item, current_x, current_y)

        local node = rt.SelectionGraphNode()
        node:set_bounds(current_x, current_y, item_w, item_h)
        self._selection_nodes[item_i] = node

        min_x = math.min(min_x, current_x)
        max_x = math.max(max_x, current_x + item_w)
        min_y = math.min(min_y, current_y)
        max_y = math.max(max_y, current_y + item_h)

        if self._orientation == rt.Orientation.HORIZONTAL then
            current_x = current_x - item_w - item_m
        else
            current_y = current_y - item_h - item_m
        end
    end

    self._final_w = max_x - min_x
    self._final_h = max_y - min_y

    for i = 1, self._n_items do
        local previous = self._selection_nodes[i-1]
        local current = self._selection_nodes[i]
        local next = self._selection_nodes[i+1]

        if self._orientation == rt.Orientation.HORIZONTAL then
            current:set_left(previous)
            if previous ~= nil then
                previous:set_right(current)
            end

            current:set_right(next)
            if next ~= nil then
                next:set_left(current)
            end
        else
            current:set_up(previous)
            if previous ~= nil then
                previous:set_down(current)
            end

            current:set_down(next)
            if next ~= nil then
                next:set_up(current)
            end
        end
    end
end

--- @override
function mn.TabBar:draw()
    if not self:get_is_allocated() then return end
    local item_i = 1
    for item in values(self._items) do
        item.frame:draw()

        local stencil_value = (meta.hash(self) + item_i) % 254 + 1
        rt.graphics.stencil(stencil_value, item.stencil)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
        item.widget:draw()
        rt.graphics.set_stencil_test()

        item_i = item_i + 1
    end
end

--- @brief set how many of the items at the end of the list should be pushed to the other site
function mn.TabBar:set_n_post_aligned_items(n)
    self._n_post_aligned_items = n
    if self._is_realized == true then
        self:reformat()
    end
end

--- @brief
function mn.TabBar:set_orientation(orientation)
    self._orientation = orientation
    if self._is_realized == true then
        self:reformat()
    end
end

--- @brief
function mn.TabBar:measure()
    return self._final_w, self._final_h
end

--- @brief
function mn.TabBar:get_selection_nodes()
    local out = {}
    for node in values(self._selection_nodes) do
        table.insert(out, node)
    end
    return out
end

--- @brief
function mn.TabBar:set_tab_selected(tab_i, b)
    local item =  self._items[tab_i]
    item.frame:set_selection_state(ternary(b, rt.SelectionState.ACTIVE, rt.SelectionState.INACTIVE))

    if item.is_selected then
        item.base:set_color(rt.Palette.GRAY_3)
    else
        if b then
            item.base:set_color(rt.settings.frame.selected_base_color)
        else
            item.base:set_color(rt.Palette.BACKGROUND)
        end
    end
end

--- @brief
function mn.TabBar:set_tab_active(tab_i, b)
    local item = self._items[tab_i]
    if b == true then
        item.base:set_color(rt.Palette.GRAY_3)
    else
        item.base:set_color(rt.Palette.BACKGROUND)
    end
    item.is_selected = b
end

--- @brief
function mn.TabBar:clear()
    self._items = {}
    self._n_items = 0
    self._selected_item_i = 0
    self._selection_nodes = {}
end