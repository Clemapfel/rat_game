mn.ScrollableListSortMode = meta.new_enum({
    BY_ID = 0,
    BY_TYPE = 1,
    BY_NAME = 2,
    BY_QUANTITY = 3,
})

--- @class mn.ScrollableList
mn.ScrollableList = meta.new_type("ScrollableList", rt.Widget, function()
    return meta.new(mn.ScrollableList, {
        _items = {}, -- cf. push
        _object_to_item = {},
        _sortings = {
            [mn.ScrollableListSortMode.BY_ID] = {}, -- Table<Number, {x, y, item_i}>
            [mn.ScrollableListSortMode.BY_QUANTITY] = {},
            [mn.ScrollableListSortMode.BY_NAME] = {},
            [mn.ScrollableListSortMode.BY_TYPE] = {},
        },
        _current_sort_mode = mn.ScrollableListSortMode.BY_ID,
        _n_items = 0,
        _stencil = rt.Rectangle(0, 0, 1, 1),
        _scrollbar = rt.Scrollbar(),
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _selected_item_i = 0,
        _selection_offset_y = 0,
        _min_y = 0,
        _max_y = 0,

        _position_x = 0,
        _position_y = 0,
        _final_height = 1,

        _label_font = rt.settings.font.default,
        _label_font_mono = rt.settings.font.default_mono,

        _
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
function mn.ScrollableList:_regenerate_sortings()
    if self._is_realized ~= true then return end
    local indices = table.seq(1, self._n_items, 1)

    -- id
    table.sort(indices, function(a, b)
        local item_a = self._items[a]
        local item_b = self._items[b]
        return item_a.object:get_id() < item_b.object:get_id()
    end)

    local current_x, current_y = self._position_x, self._position_y
    for index_i = 1, self._n_items do
        local item_i = indices[index_i]
        self._sortings[mn.ScrollableListSortMode.BY_ID][index_i] = {
            x = current_x,
            y = current_y,
            item_i = item_i
        }
        current_y = current_y + self._items[item_i].height
    end

    -- type
    table.sort(indices, function(a, b)
        local item_a = self._items[a].object
        local item_b = self._items[b].object

        local properties = {}
        local i = 1
        for item in range(item_a, item_b) do
            if meta.isa(item, bt.Move) then
                properties[i] = item:get_id()
            elseif meta.isa(item, bt.Equip) then
                properties[i] = item:get_type()
            elseif meta.isa(item, bt.Consumable) then
                properties[i] = item:get_max_n_uses()
            end
            i = i + 1
        end

        return properties[1] < properties[2]
    end)

    current_x, current_y = self._position_x, self._position_y
    for index_i = 1, self._n_items do
        local item_i = indices[index_i]
        self._sortings[mn.ScrollableListSortMode.BY_TYPE][index_i] = {
            x = current_x,
            y = current_y,
            item_i = item_i
        }
        current_y = current_y + self._items[item_i].height
    end

    -- name
    table.sort(indices, function(a, b)
        local item_a = self._items[a]
        local item_b = self._items[b]
        return item_a.object:get_name() < item_b.object:get_name()
    end)

    current_x, current_y = self._position_x, self._position_y
    for index_i = 1, self._n_items do
        local item_i = indices[index_i]
        self._sortings[mn.ScrollableListSortMode.BY_NAME][index_i] = {
            x = current_x,
            y = current_y,
            item_i = item_i
        }
        current_y = current_y + self._items[item_i].height
    end

    -- quantity (stable sort, retains by name
    table.sort(indices, function(a, b)
        local item_a = self._items[a]
        local item_b = self._items[b]

        return item_a.quantity > item_b.quantity
    end)

    current_x, current_y = self._position_x, self._position_y
    for index_i = 1, self._n_items do
        local item_i = indices[index_i]
        self._sortings[mn.ScrollableListSortMode.BY_QUANTITY][index_i] = {
            x = current_x,
            y = current_y,
            item_i = item_i
        }
        current_y = current_y + self._items[item_i].height
    end
end

--- @brief
function mn.ScrollableList:set_sort_mode(mode)
    meta.assert_enum(mode, mn.ScrollableListSortMode)
    self._current_sort_mode = mode
end

--- @brief
function mn.ScrollableList._update_item(item)
    item.name_label:set_text(mn.ScrollableList._format_name_label(item.object:get_name()))
    item.quantity_label:set_text(mn.ScrollableList._format_quantity_label(item.quantity))
end

--- @brief
function mn.ScrollableList:push(...)
    for pair in range(...) do
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
            base_outline = rt.Rectangle(0, 0, 1, 1)
        }

        if self._is_realized then
            self._realize_item(to_insert)
        end

        table.insert(self._items, to_insert)
        self._object_to_item[object] = to_insert

        if self._selected_item_i == 0 then self._selected_item_i = 1 end
        self._n_items = self._n_items + 1
    end

    self:_regenerate_sortings()
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
    local m = rt.settings.margin_unit
    local scrollbar_width = 1.5 * m
    local scrollbar_margin = 0.5 * m
    local item_w = width - (scrollbar_width + scrollbar_margin)
    local current_x, current_y = x, y

    self._position_x, self._position_y = current_x, current_y
    for item in values(self._items) do
        local x, y = 0, 0
        local sprite_w, sprite_h = item.sprite:get_resolution()
        sprite_w = sprite_w * 1
        sprite_h = sprite_h * 1
        local sprite_x = x + 0.5 * m
        item.sprite:fit_into(sprite_x, y, sprite_w, sprite_h)

        local quantity_w, quantity_h = item.quantity_label:measure()
        local quantity_x = x + item_w - quantity_w - m
        item.quantity_label:fit_into(quantity_x, y + 0.5 * sprite_h - 0.5 * quantity_h, POSITIVE_INFINITY, quantity_h)

        local label_w, label_h = item.name_label:measure()
        item.name_label:fit_into(sprite_x + sprite_w + m, y + 0.5 * sprite_h - 0.5 * label_h, POSITIVE_INFINITY, label_h)

        local base_h = math.max(sprite_h, label_h, quantity_h)
        for base in range(item.selected_base, item.unselected_base, item.base_outline) do
            base:resize(x, y, item_w, base_h)
        end
        item.height = base_h
        current_y = current_y + item.height
    end

    self._stencil:resize(x - 1, y - 1, width - scrollbar_width + 2, height + 2)
    self._final_height = height
    self._scrollbar:fit_into(x + width - (scrollbar_width) , y, scrollbar_width, height)
    self._scrollbar:set_n_pages(self._n_items)
    self._scrollbar:set_page_index(self._selected_item_i)

    self._base:resize(x, y, width, height)
    self._base_outline:resize(x, y, width, height)

    self._min_y = y
    self._max_y = y + height

    self:_regenerate_sortings()
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
        local entry = self._sortings[self._current_sort_mode][i]
        local item = self._items[entry.item_i]

        rt.graphics.origin()
        rt.graphics.translate(entry.x, entry.y + self._selection_offset_y)

        if i == self._selected_item_i then
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
    if self._selected_item_i > 1 then
        self._selected_item_i = self._selected_item_i - 1
        self._scrollbar:set_page_index(self._selected_item_i)

        local entry = self._sortings[self._current_sort_mode][self._selected_item_i]
        local item = self._items[entry.item_i]
        local position_y = entry.y
        if position_y + self._selection_offset_y < self._min_y then
            self._selection_offset_y = self._selection_offset_y + item.height
        end
    end
end

--- @brief
function mn.ScrollableList:move_down()
    if self._selected_item_i < self._n_items then
        self._selected_item_i = self._selected_item_i + 1
        self._scrollbar:set_page_index(self._selected_item_i)

        local entry = self._sortings[self._current_sort_mode][self._selected_item_i]
        local item = self._items[entry.item_i]
        local position_y = entry.y
        if position_y + item.height + self._selection_offset_y > self._max_y then
            self._selection_offset_y = self._selection_offset_y - item.height
        end
    end
end

--- @brief
function mn.ScrollableList:get_selected()
    local item = self._items[self._sortings[self._current_sort_mode][self._selected_item_i].item_i]
    if item ~= nil then
        return item.object
    else
        return nil
    end
end

--- @brief
function mn.ScrollableList:take(object)
    local item = self._object_to_item[object]
    if item == nil then
        rt.warning("In mn.ScrollableList:take: trying to take object " .. object:get_id() .. " which is not part of list")
        return
    end

    if item.quantity <= 1 then
        local item_i = 1
        for i = 1, self._n_items do
            if self._items[i] == item then
                item_i = i
                break
            end
        end
        table.remove(self._items, item_i)
        self._object_to_item[object] = nil
        self._n_items = self._n_items - 1

        -- update item positions without reformatting
        if self._n_items == 0 then
            self._selected_item_i = 0
        end
        self:_regenerate_sortings()
    else
        item.quantity = item.quantity - 1
        mn.ScrollableList._update_item(item)
    end
end

--- @brief
function mn.ScrollableList:add(object, new_quantity)
    new_quantity = which(new_quantity, 1)
    local item = self._object_to_item[object]
    if item ~= nil then
        item.quantity = item.quantity + new_quantity
        mn.ScrollableList._update_item(item)
    else
        self:push({object, new_quantity})
        self:reformat()
    end
end