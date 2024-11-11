rt.settings.menu.slots = {
    sprite_resolution = 32,
    sprite_scale = 2,
    frame_unselected_thickness = 1,
    frame_selected_thickness = 2,
    snapshot_padding = 5
}

mn.SlotType = meta.new_enum("SlotType", {
    MOVE = "MOVE",
    EQUIP = "EQUIP",
    CONSUMABLE = "CONSUMABLE",
    INTRINSIC = "INTRINSIC"
})

--- @class mn.Slots
--- @param layout List<List<mn.SlotType>>
mn.Slots = meta.new_type("MenuSlots", rt.Widget, function(layout)
    return meta.new(mn.Slots, {
        _layout = layout,
        _items = {},
        _n_slots = 0,
        _slot_i_to_item = {},
        _pre_realize_items = {},
        _item_to_sprite = {},
        _selected_slots = {},

        _frame = rt.Frame(),
        _snapshot = rt.RenderTexture(),
        _snapshot_x = 0,
        _snapshot_y = 0,
        _slot_x = 0,
        _slot_y = 0
    })
end)

--- @override
function mn.Slots:realize()
    if self:already_realized() then return end

    self._frame:realize()

    do -- sanitize layout
        local to_remove = {}
        for i = 1, sizeof(self._layout) do
            if sizeof(self._layout[i]) == 0 then
                table.insert(to_remove, i)
            end
        end
        for i in values(to_remove) do
            table.remove(self._layout, i)
        end
    end

    local slot_i = 1
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
                    frame_selected = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                    frame_outline = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                }
            elseif type == mn.SlotType.MOVE or type == mn.SlotType.INTRINSIC then
                to_insert = {
                    base = rt.Rectangle(0, 0, 1, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Rectangle(0, 0, 1, 1),
                    frame_selected = rt.Rectangle(0, 0, 1, 1),
                    frame_outline = rt.Rectangle(0, 0, 1, 1)
                }
                to_insert.base:set_corner_radius(rt.settings.frame.corner_radius)
                for frame in range(to_insert.frame, to_insert.frame_selected) do
                    frame:set_corner_radius(rt.settings.frame.corner_radius)
                end
                to_insert.frame_outline:set_corner_radius(rt.settings.frame.corner_radius)
            elseif type == mn.SlotType.CONSUMABLE then
                to_insert = {
                    base = rt.Circle(0, 0, 1, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Circle(0, 0, 1, 1),
                    frame_selected = rt.Circle(0, 0, 1, 1),
                    frame_outline = rt.Circle(0, 0, 1, 1)
                }
                --[[
            elseif type == mn.SlotType.INTRINSIC then
                to_insert = {
                    base = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                    base_inlay = rt.Circle(0, 0, 1, 1),
                    frame = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                    frame_outline = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
                }
                ]]--
            else
                rt.error("In mn.Slots:realize: unrecognized slot type at `" .. row_i .. ", " .. column_i .. "`: `" .. type .. "`")
            end

            to_insert.sprite = nil
            to_insert.type = type

            local base_color = rt.Palette.GRAY_7
            to_insert.base:set_color(base_color)
            to_insert.base_inlay:set_color(rt.color_darken(base_color, 0.1))

            for frame in range(to_insert.frame, to_insert.frame_selected) do
                frame:set_is_outline(true)
            end

            to_insert.frame:set_color(rt.Palette.GRAY_5)
            to_insert.frame:set_line_width(rt.settings.menu.slots.frame_unselected_thickness)
            to_insert.frame_selected:set_color(rt.Palette.SELECTION)
            to_insert.frame_selected:set_line_width(rt.settings.menu.slots.frame_selected_thickness)

            to_insert.frame_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
            to_insert.frame_outline:set_line_width(3)
            to_insert.frame_outline:set_is_outline(true)
            to_insert.bounds = rt.AABB(0, 0, 1, 1)
            to_insert.selection_node = rt.SelectionGraphNode()
            to_insert.is_visible = true

            table.insert(row, to_insert)
            self._slot_i_to_item[slot_i] = to_insert
            slot_i = slot_i + 1
        end
    end

    self._n_slots = slot_i - 1
end

--- @override
function mn.Slots:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local inlay_factor = 0.7

    local start_x, start_y = 0 + m, 0 + m
    self._slot_x, self._slot_y = x, y
    local current_x, current_y = start_x, start_y
    local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale
    local slot_h = slot_w
    local radius = 0.5 * slot_w
    local n_rows = sizeof(self._items)
    local slot_vertical_m = ((height - 4 * m) - (n_rows * slot_h)) / (n_rows + 1)
    slot_vertical_m = math.max(slot_vertical_m, m)
    current_y = start_y + clamp((height - 2 * m - (n_rows * slot_h) - (n_rows - 1) * slot_vertical_m) / 2, 0)
    for row_i = 1, n_rows do
        local row = self._items[row_i]
        local n_slots = sizeof(row)
        local slots_xm = ((width - 2 * m) - (n_slots * slot_w)) / (n_slots + 1)
        slots_xm = math.max(slots_xm, m)

        current_x = current_x + slots_xm
        for slot_i = 1, #row do
            local slot = row[slot_i]
            if slot.type == mn.SlotType.EQUIP then
                local center_x, center_y = current_x + 0.5 * slot_w, current_y + 0.5 * slot_h
                local points = {}
                local n_sides = 6
                for i = 1, n_sides do
                    local point_x, point_y = rt.translate_point_by_angle(center_x, center_y, radius * 1.1, i / n_sides * (2 * math.pi))
                    table.insert(points, point_x)
                    table.insert(points, point_y)
                end

                for shape in range(slot.base, slot.frame, slot.frame_selected, slot.frame_outline) do
                    shape:resize(table.unpack(points))
                end
            elseif slot.type == mn.SlotType.CONSUMABLE then
                for shape in range(slot.base, slot.frame, slot.frame_selected, slot.frame_outline) do
                    shape:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * slot_w, 0.5 * slot_h)
                end
            elseif slot.type == mn.SlotType.MOVE or slot.type == mn.SlotType.INTRINSIC then
                for shape in range(slot.base, slot.frame, slot.frame_selected, slot.frame_outline) do
                    shape:resize(current_x, current_y, slot_w, slot_h)
                end
            --[[
            elseif slot.type == mn.SlotType.INTRINSIC then
                local points = {}
                local center_x, center_y = current_x + 0.5 * slot_w, current_y + 0.5 * slot_h
                for i = 1, 4 do
                    local point_x, point_y = rt.translate_point_by_angle(center_x, center_y, radius * 1.3, i / 4 * (2 * math.pi))
                    table.insert(points, point_x)
                    table.insert(points, point_y)
                end

                for shape in range(slot.base, slot.frame, slot.frame_outline) do
                    shape:resize(table.unpack(points))
                end
                ]]--
            end

            slot.bounds = rt.AABB(current_x, current_y, slot_w, slot_w)
            if slot.sprite ~= nil then
                slot.sprite:fit_into(slot.bounds)
            end

            slot.base_inlay:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * inlay_factor * slot_w, 0.5 * inlay_factor * slot_w)

            slot.selection_node:set_bounds(current_x + self._slot_x, current_y + self._slot_y, slot_w, slot_w)

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

            current_x = current_x + slot_w + slots_xm
        end

        current_x = start_x
        current_y = current_y + slot_h + slot_vertical_m
    end

    self._frame:fit_into(0, 0, width, height)

    for i = 1, self._n_slots do
        self:set_object(i, self._pre_realize_items[i])
    end
    self._pre_realize_items = {}

    local padding = rt.settings.menu.slots.snapshot_padding
    local snapshot_w, snapshot_h = width + 2 * padding, height + 2 * padding
    if self._snapshot:get_width() ~= snapshot_w or self._snapshot:get_height() ~= snapshot_h then
        self._snapshot = rt.RenderTexture(snapshot_w, snapshot_h)
    end

    self:_update_snapshot()
    self._snapshot_x, self._snapshot_y = x - padding, y - padding
end

function mn.Slots:_update_snapshot()
    local padding = rt.settings.menu.slots.snapshot_padding

    love.graphics.push()
    self._snapshot:bind()

    love.graphics.translate(padding, padding)
    self._frame:draw()
    for row in values(self._items) do
        for item in values(row) do
            item.base:draw()
            item.base_inlay:draw()
            item.frame_outline:draw()
            item.frame:draw()
        end
    end

    for _, sprite in pairs(self._item_to_sprite) do
        sprite:draw()
    end

    self._snapshot:unbind()
    love.graphics.pop()
end

--- @override
function mn.Slots:draw()
    if not self:get_is_allocated() then return end
    self._snapshot:draw(self._snapshot_x, self._snapshot_y)

    love.graphics.translate(self._slot_x, self._slot_y)
    for item in keys(self._selected_slots) do
        item.frame_selected:draw()
    end
    love.graphics.translate(-self._slot_x, -self._slot_y)
end

--- @override
function mn.Slots:measure()
    local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale
    local n_rows, max_row_width = 0, NEGATIVE_INFINITY
    for row in values(self._items) do
        n_rows = n_rows + 1
        max_row_width = math.max(max_row_width, sizeof(row))
    end

    local m = rt.settings.margin_unit
    local thickness = self._frame:get_thickness()
    local slot_thickness = rt.settings.menu.slots.frame_unselected_thickness
    return max_row_width * slot_w + (max_row_width + 2) * m + 2 * thickness + max_row_width * slot_thickness * 2,
        n_rows * slot_w + (n_rows + 1) * m + 2 * thickness + n_rows * slot_thickness * 2
end

--- @brief
function mn.Slots:set_object(slot_i, object, label)
    if self._is_realized == false then
        self._pre_realize_items[slot_i] = object
    else
        local item = self._slot_i_to_item[slot_i]
        if item == nil then
            rt.error("In mn.Slots:set_object: slot index `" .. slot_i .. "` is out of bounds for slots with `" .. sizeof(self._slot_i_to_item) .. "` many slots")
        end

        if object == nil then
            item.sprite = nil
            self._item_to_sprite[item] = nil
        else
            item.sprite = rt.Sprite(object:get_sprite_id())
            if label ~= nil then
                item.sprite:set_bottom_right_child(label)
            end
            item.sprite:realize()
            item.sprite:fit_into(item.bounds)
            self._item_to_sprite[item] = item.sprite
        end

        item.object = object
    end

    self:_update_snapshot()
end

--- @brief
function mn.Slots:clear()
    for row in values(self._items) do
        for item in values(row) do
            item.sprite = nil
            item.object = nil
        end
    end

    self._item_to_sprite = {}
    self:_update_snapshot()
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
function mn.Slots:set_slot_selection_state(slot_i, selection_state)
    local item = self._slot_i_to_item[slot_i]
    local unselected_opacity = 0.5
    if selection_state == rt.SelectionState.ACTIVE then
        for shape in range(item.base, item.base_inlay, item.frame) do
            shape:set_opacity(1)
        end
        self._selected_slots[item] = true
    elseif selection_state == rt.SelectionState.INACTIVE then
        for shape in range(item.base, item.base_inlay, item.frame) do
            shape:set_opacity(1)
        end
        self._selected_slots[item] = nil
    elseif selection_state == rt.SelectionState.UNSELECTED then
        for shape in range(item.base, item.base_inlay, item.frame) do
            shape:set_opacity(unselected_opacity)
        end
        self._selected_slots[item] = nil
    end
end

--- @brief
function mn.Slots:set_selection_state(state)
    self._frame:set_selection_state(state)
    self:_update_snapshot()
end

--- @brief
function mn.Slots:get_slot_aabb(slot_i)
    local item = self._slot_i_to_item[slot_i]
    return item.selection_node:get_bounds()
end

--- @brief
function mn.Slots:set_opacity(alpha)
    self._opacity = alpha
    self._frame:set_opacity(alpha)
    for item in values(self._slot_i_to_item) do
        item.base:set_opacity(alpha)
        item.base_inlay:set_opacity(alpha)
        item.frame:set_opacity(alpha)
        item.frame_selected:set_opacity(alpha)
        item.frame_outline:set_opacity(alpha)
    end
    self:_update_snapshot()
end

--- @brief
function mn.Slots:sort()
    local by_type = {
        [mn.SlotType.MOVE] = {},
        [mn.SlotType.CONSUMABLE] = {},
        [mn.SlotType.EQUIP] = {},
        [mn.SlotType.INTRINSIC] = {}
    }

    for slot_i = 1, self._n_slots do
        local item = self._slot_i_to_item[slot_i]
        if item.object ~= nil then
            table.insert(by_type[item.type], item.object)
        end
    end

    for slot_i = 1, self._n_slots do
        local item = self._slot_i_to_item[slot_i]
        local to_push = table.pop_front(by_type[item.type])
        self:set_object(slot_i, to_push)
    end

    self:_update_snapshot()
end

--- @brief
function mn.Slots:set_slot_object_visible(slot_i, b)
    self._slot_i_to_item[slot_i].is_visible = b
    self:_update_snapshot()
end