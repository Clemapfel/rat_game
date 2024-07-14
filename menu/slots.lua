rt.settings.menu.slots = {
    sprite_resolution = 32,
    sprite_scale = 2,
    frame_unselected_thickness = 1,
    frame_selected_thickness = 2
}

mn.SlotType = meta.new_enum({
    MOVE = "MOVE",
    EQUIP = "EQUIP",
    CONSUMABLE = "CONSUMABLE"
})

--- @class mn.Slots
--- @param layout List<List<mn.SlotType>>
mn.Slots = meta.new_type("MenuSlots", rt.Widget, function(layout)
    return meta.new(mn.Slots, {
        _layout = layout,
        _items = {},
        _n_slots = 0,
        _slot_i_to_item = {},
        _frame = rt.Frame(),
    })
end)

--- @override
function mn.Slots:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()

    local n_slots = 0
    local n_rows = sizeof(self._layout)
    for row_i = 1, n_rows do
        local row_layout = self._layout[row_i]
        local n_columns = sizeof(row_layout)
        local row = {}
        table.insert(self._items, row)
        for column_i = 1, n_columns do
            local type = row_layout[column_i]
            local to_insert
            if type == mn.SlotType.EQUIP then
                to_insert = {
                    base = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                }
            elseif type == mn.SlotType.MOVE then
                to_insert = {
                    base = rt.Rectangle(0, 0, 1, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Rectangle(0, 0, 1, 1),
                }
                to_insert.base:set_corner_radius(rt.settings.frame.corner_radius)
                to_insert.frame:set_corner_radius(rt.settings.frame.corner_radius)
            elseif type == mn.SlotType.CONSUMABLE then
                to_insert = {
                    base = rt.Circle(0, 0, 1, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Circle(0, 0, 1, 1),
                }
            else
                rt.error("In mn.Slots:realize: unrecognized slot type at `" .. row_i .. ", " .. column_i .. "`: `" .. type .. "`")
            end

            to_insert.sprite = nil
            to_insert.type = type

            local base_color = rt.Palette.GRAY_5
            to_insert.base:set_color(base_color)
            to_insert.base_inlay:set_color(rt.color_darken(base_color, 0.1))
            to_insert.frame:set_color(rt.Palette.GRAY_4)
            to_insert.frame:set_line_width(rt.settings.menu.slots.frame_unselected_thickness)
            to_insert.frame:set_is_outline(true)
            to_insert.bounds = rt.AABB(0, 0, 1, 1)
            to_insert.selection_node = mn.SelectionGraphNode()

            table.insert(row, to_insert)
            self._slot_i_to_item[slot_i] = to_insert
            slot_i = slot_i + 1
        end
    end

    self._n_slots = slot_i
end

--- @override
function mn.Slots:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    local m = rt.settings.margin_unit
    local inlay_factor = 0.7

    local start_x, start_y = x + m, y + m
    local current_x, current_y = start_x, start_y
    local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale
    local slot_h = slot_w
    local radius = 0.5 * slot_w
    local n_rows = sizeof(self._items)
    local slot_vertical_m = ((height - 2 * m) - (n_rows * slot_h)) / (n_rows + 1)
    slot_vertical_m = math.ceil(slot_vertical_m)
    current_y = current_y + slot_vertical_m
    slot_vertical_m = math.max(slot_vertical_m, m)

    for row_i = 1, n_rows do
        local row = self._items[row_i]
        local n_slots = sizeof(row)
        local slot_m = ((width - 2 * m) - (n_slots * slot_w)) / (n_slots + 1)
        slot_m = math.max(slot_m, m)

        current_x = current_x + slot_m
        for slot_i = 1, #row do
            local slot = row[slot_i]
            if slot.type == mn.SlotType.EQUIP then
                local center_x, center_y = current_x + 0.5 * slot_w, current_y + 0.5 * slot_h
                local points = {}
                local n_sides = 6
                for i = 1, n_sides do
                    local point_x, point_y = rt.translate_point_by_angle(center_x, center_y, radius * 1.1, rt.degrees_to_radians(i / n_sides * 360))
                    table.insert(points, point_x)
                    table.insert(points, point_y)
                end

                for shape in range(slot.base, slot.frame) do
                    shape:resize(table.unpack(points))
                end
            elseif slot.type == mn.SlotType.CONSUMABLE then
                for shape in range(slot.base, slot.frame) do
                    shape:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * slot_w, 0.5 * slot_h)
                end
            elseif slot.type == mn.SlotType.MOVE then
                for shape in range(slot.base, slot.frame) do
                    shape:resize(current_x, current_y, slot_w, slot_h)
                end
            end

            slot.bounds = rt.AABB(current_x, current_y, slot_w, slot_w)
            if slot.sprite ~= nil then
                slot.sprite:fit_into(slot.bounds)
            end

            slot.base_inlay:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * inlay_factor * slot_w, 0.5 * inlay_factor * slot_w)

            slot.selection_node:set_aabb(current_x, current_y, slot_w, slot_w)

            local left, right = row[slot_i - 1], row[slot_i + 1]
            slot.selection_node:set_left(nil)
            if left ~= nil then
                slot.selection_node:set_left(left.selection_node)
            end

            slot.selection_node:set_right(nil)
            if right ~= nil then
                slot.selection_node:set_right(right.selection_node)
            end

            slot.selection_node:set_up(nil)
            local up_row = self._items[row_i - 1]
            if up_row ~= nil then
                local up_item = up_row[slot_i]
                if up_item ~= nil then
                    slot.selection_node:set_up(up_item.selection_node)
                end
            end

            slot.selection_node:set_down(nil)
            local down_row = self._items[row_i + 1]
            if down_row ~= nil then
                local down_item = down_row[slot_i]
                if down_item ~= nil then
                    slot.selection_node:set_down(down_item.selection_node)
                end
            end

            current_x = current_x + slot_w + slot_m
        end

        current_x = start_x
        current_y = current_y + slot_h + slot_vertical_m
    end

    self._frame:fit_into(x, y, width, height)
end

--- @override
function mn.Slots:draw()
    if self._is_realized ~= true then return end
    self._frame:draw()
    for row in values(self._items) do
        for item in values(row) do
            item.base:draw()
            item.base_inlay:draw()
            item.frame:draw()
            if item.sprite ~= nil then
                item.sprite:draw()
            end
        end
    end
end

--- @override
function mn.Slots:measure()
    local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale

    local n_rows, max_row_width = 0, NEGATIVE_INFINITY
    for row in values(self._items) do
        n_rows = n_rows + 1
        max_row_width = math.max(max_row_width, sizeof(row))
    end

    return max_row_width * slot_w, n_rows * slot_w
end

--- @brief
function mn.Slots:set_object(slot_i, object)
    -- TODO: what if called before realize?
    local item = self._slot_i_to_item[slot_i]
    if item == nil then
        rt.error("In mn.Slots:set_object: slot index `" .. slot_i .. "` is out of bounds for slots with `" .. sizeof(self._slot_i_to_item) .. "` many slots")
    end

    if object == nil then
        item.sprite = nil
    else
        item.sprite = rt.Sprite(object:get_sprite_id())
        item.sprite:realize()
        item.sprite:fit_into(item.bounds)
    end

    item.object = object
end

--- @brief
function mn.Slots:get_object(slot_i)
    local item = self._slot_i_to_item[slot_i]
    if item == nil then return nil end
    return item.object
end

--- @brief
function mn.Slots:get_first_unoccupied_slot_i()
    for slot_i = 1, self._n_slots do
        if self._slot_i_to_item[slot_i]:get_object() == nil then
            return slot_i
        end
    end
    return nil
end

--- @brief
function mn.Slots:clear()
    for row in values(self._items) do
        for item in values(row) do
            item.sprite = nil
        end
    end
end

--- @brief
function mn.Slots:get_selection_nodes()
    local out = {}
    for row in values(self._items) do
        for item in values(row) do
            table.insert(out, item.selection_node)
        end
    end
    return out
end

--- @brief
function mn.Slots:set_slot_selected(slot_i, b)
    meta.assert_boolean(b)
    local item = self._slot_i_to_item[slot_i]
    if b then
        item.frame:set_color(rt.Palette.SELECTION)
        item.frame:set_line_width(rt.settings.menu.slots.frame_selected_thickness)
    else
        item.frame:set_color(rt.Palette.GRAY_4)
        item.frame:set_line_width(rt.settings.menu.slots.frame_unselected_thickness)
    end
end

--- @brief
function mn.Slots:set_selected(b)
    self._frame:set_selected(b)
end