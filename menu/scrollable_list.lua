--- @class mn.ScrollableList
mn.ScrollableList = meta.new_type("ScrollableList", rt.Widget, function()
    return meta.new(mn.ScrollableList, {
        _items = {}, -- cf. push
        _n_items = 0,
        _stencil = rt.Rectangle(0, 0, 1, 1),
        _scrollbar = rt.Scrollbar(),
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _selected_item = 0,
        _selection_offset_y = 0,
        _min_y = 0,
        _max_y = 0,

        _label_font = rt.settings.font.default_small,
        _label_font_mono = rt.settings.font.default_mono_small
    })
end)

--- @brief [internal]
function mn.ScrollableList._format_name_label(str)
    return "<o>" .. str .. "</o>"
end

--- @brief [internal]
function mn.ScrollableList._format_quantity_label(str)
    return "<o><mono>" .. str .. "</o></mono>"
end

--- @brief [internal]
function mn.ScrollableList._realize_item(item)
    item.sprite:realize()
    item.name_label:realize()
    item.quantity_label:realize()

    for label in range(item.name_label, item.quantity_label) do
        label:set_justify_mode(rt.JustifyMode.LEFT)
    end

    item.base_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    item.unselected_base:set_color(rt.Palette.GRAY_4)
    item.selected_base:set_color(rt.Palette.GRAY_3)

    for rectangle in range(item.base_outline, item.unselected_base, item.selected_base) do
        rectangle:set_corner_radius(rt.settings.frame.corner_radius)
    end

    item.base_outline:set_is_outline(true)
end

--- @brief
function mn.ScrollableList:push(...)
    for pair in values({...}) do
        local object = pair[1]
        local quantity = pair[2]
        local to_insert = {
            object = object,
            quantity = quantity,
            sprite = rt.Sprite(object:get_sprite_id()),
            name_label = rt.Label(self._format_name_label(object:get_name()), self._label_font, self._label_font_mono),
            quantity_label = rt.Label(self._format_quantity_label(quantity), self._label_font, self._label_font_mono),
            unselected_base = rt.Rectangle(0, 0, 1, 1),
            selected_base = rt.Rectangle(0, 0, 1, 1),
            base_outline = rt.Rectangle(0, 0, 1, 1),
            position_x = 0,
            position_y = 0
        }

        if self._is_realized then
            self._realize_item(to_insert)
        end

        table.insert(self._items, to_insert)

        if self._selected_item == 0 then self._selected_item = self._n_items end
        self._n_items = self._n_items + 1
    end
end

--- @brief
function mn.ScrollableList:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._scrollbar:realize()
    for item in values(self._items) do
        self._realize_item(item)
    end

    self._base:set_corner_radius(rt.settings.frame.corner_radius)
    self._base:set_color(rt.Palette.BACKGROUND)
    self._base_outline:set_corner_radius(rt.settings.frame.corner_radius)
    self._base_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    self._base_outline:set_is_outline(true)
end

--- @brief
function mn.ScrollableList:size_allocate(x, y, width, height)
    local scrollbar_width = 20
    local m = rt.settings.margin_unit
    local item_w = width - scrollbar_width
    local current_x, current_y = x, y

    for item in values(self._items) do
        local x, y = 0, 0
        local sprite_w, sprite_h = item.sprite:get_resolution()
        item.sprite:fit_into(x, y, sprite_w, sprite_h)

        local quantity_w, quantity_h = item.quantity_label:measure()
        local quantity_x = x + item_w - quantity_w - m
        item.quantity_label:fit_into(quantity_x, y + 0.5 * sprite_h - 0.5 * quantity_h, POSITIVE_INFINITY, quantity_h)

        local label_w, label_h = item.name_label:measure()
        item.name_label:fit_into(x + sprite_w + m, y + 0.5 * sprite_h - 0.5 * label_h, POSITIVE_INFINITY, label_h)

        local base_h = math.max(sprite_h, label_h, quantity_h)
        for base in range(item.selected_base, item.unselected_base, item.base_outline) do
            base:resize(x, y, item_w, base_h)
        end
        item.height = base_h

        item.position_x, item.position_y = current_x, current_y
        current_y = current_y + item.height
    end

    self._stencil:resize(x - 1, y - 1, width - scrollbar_width + 2, height + 2)
    self._scrollbar:fit_into(x + width - scrollbar_width, y, scrollbar_width, height)
    self._scrollbar:set_n_pages(self._n_items)
    self._scrollbar:set_page_index(self._selected_item)

    self._base:resize(x, y, width, height)
    self._base_outline:resize(x, y, width, height)

    self._min_y = y
    self._max_y = y + height
end

--- @override
function mn.ScrollableList:draw()
    self._base:draw()
    self._base_outline:draw()

    local stencil_value = meta.hash(mn.ScrollableList) % 255
    rt.graphics.stencil(stencil_value, self._stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)

    rt.graphics.push()
    for i = 1, self._n_items do
        local item = self._items[i]
        rt.graphics.origin()
        rt.graphics.translate(item.position_x, item.position_y + self._selection_offset_y)

        if i == self._selected_item then
            item.selected_base:draw()
        else
            item.unselected_base:draw()
        end
        item.base_outline:draw()

        item.sprite:draw()
        item.name_label:draw()
        item.quantity_label:draw()
    end

    rt.graphics.pop()

    rt.graphics.set_stencil_test()
    self._scrollbar:draw()
end

--- @brief
function mn.ScrollableList:move_up()
    if self._selected_item > 1 then
        self._selected_item = self._selected_item - 1
        self._scrollbar:set_page_index(self._selected_item)

        local item = self._items[self._selected_item]
        if item.position_y + self._selection_offset_y < self._min_y then
            self._selection_offset_y = self._selection_offset_y + item.height
        end
    end
end

--- @brief
function mn.ScrollableList:move_down()
    if self._selected_item < self._n_items then
        self._selected_item = self._selected_item + 1
        self._scrollbar:set_page_index(self._selected_item)

        local item = self._items[self._selected_item]
        if item.position_y + item.height + self._selection_offset_y > self._max_y then
            self._selection_offset_y = self._selection_offset_y - item.height
        end
    end
end