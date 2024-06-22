--- @class mn.ScrollableList
mn.ScrollableList = meta.new_type("ScrollableList", rt.Widget, function()
    return meta.new(mn.ScrollableList, {
        _items = {},
        _n_items = 0,
        _stencil = rt.Rectangle(0, 0, 1, 1),
        _scrollbar = rt.Scrollbar(),
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _selected_item = 0
    })
end)

--- @brief
function mn.ScrollableList:push(item, ...)
    local to_insert = {
        widget = item,
        is_selected = false,
        position_x = 0,
        position_y = 0,
        height = 0
    }
    table.insert(self._items, to_insert)

    if self._is_realized then
        to_insert.widget:realize()
    end
    self._n_items = self._n_items + 1

    if self._selected_item == 0 then
        self._selected_item = 1
    end
end

--- @override
function mn.ScrollableList:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._scrollbar:realize()
    for entry in values(self._items) do
        entry.widget:realize()
    end

    self._base:set_corner_radius(rt.settings.frame.corner_radius)
    self._base:set_color(rt.Palette.BACKGROUND)
    self._base_outline:set_corner_radius(rt.settings.frame.corner_radius)
    self._base_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    self._base_outline:set_is_outline(true)

end

--- @override
function mn.ScrollableList:size_allocate(x, y, width, height)
    local scrollbar_width = 20
    local m = rt.settings.margin_unit
    local item_bounds = rt.AABB(x, y, width - scrollbar_width, 0)
    local current_x, current_y = item_bounds.x, item_bounds.y
    self._scrollbar:fit_into(current_x + width - scrollbar_width, current_y, scrollbar_width, height)
    for entry in values(self._items) do
        entry.height = select(2, entry.widget:measure())
        entry.widget:fit_into(0, 0, item_bounds.width, entry.height)
        entry.position_x = current_x
        entry.position_y = current_y
        current_y = current_y + entry.height
    end

    self._stencil:resize(x - 1, y - 1, width - scrollbar_width + 2, height + 2)
    self._scrollbar:set_n_pages(self._n_items)
    self._scrollbar:set_page_index(self._selected_item)

    self._base:resize(x, y, width, height)
    self._base_outline:resize(x, y, width, height)
end

--- @override
function mn.ScrollableList:draw()

    self._base:draw()
    self._base_outline:draw()

    local stencil_value = meta.hash(mn.ScrollableList) % 255
    rt.graphics.stencil(stencil_value, self._stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    for item in values(self._items) do
        rt.graphics.origin()
        rt.graphics.translate(item.position_x, item.position_y)
        item.widget:draw()
    end

    rt.graphics.set_stencil_test()
    rt.graphics.origin()
    self._scrollbar:draw()
end