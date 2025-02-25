rt.settings.menu.slots = {
    sprite_resolution = 32,
    sprite_scale = 2
}

--- @class mn.Slots
mn.Slots = meta.new_type("MenuSlots", rt.Widget, function(n_equip_slots, n_consumable_slots, n_move_slots)
    return meta.new(mn.Slots, {
        _n_equip_slots = n_equip_slots,
        _equip_slots = {},
        _n_consumable_slots = n_consumable_slots,
        _consumable_slots = {},
        _n_move_slots = n_move_slots,
        _move_slots = {},

        _frame = rt.Frame(),
        _frame_was_allocated = false
    })
end)

--- @override
function mn.Slots:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for slot_i = 1, self._n_equip_slots do
        local to_insert = {
            base = rt.Rectangle(0, 0, 1, 1),
            base_inlay = rt.Circle(0, 0, 1, 1),
            frame = rt.Rectangle(0, 0, 1, 1),
            sprite = nil
        }

        for rect in range(to_insert.base, to_insert.frame) do
            rect:set_corner_radius(rt.settings.frame.corner_radius)
        end

        table.insert(self._equip_slots, to_insert)
    end

    for slot_i = 1, self._n_consumable_slots do
        local to_insert = {
            base = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
            base_inlay = rt.Circle(0, 0, 1, 1),
            frame = rt.Polygon(0, 0, 1, 1, 1, 0, 0, 1),
            sprite = nil
        }

        table.insert(self._consumable_slots, to_insert)
    end

    for slot_i = 1, self._n_move_slots do
        local to_insert = {
            base = rt.Circle(0, 0, 1, 1),
            base_inlay = rt.Circle(0, 0, 1, 1),
            frame = rt.Circle(0, 0, 1, 1),
            sprite = nil
        }

        table.insert(self._move_slots, to_insert)
    end

    for t in range(self._equip_slots, self._consumable_slots, self._move_slots) do
        for slot in values(t) do
            local base_color = rt.Palette.GRAY_4
            slot.base:set_color(base_color)
            slot.base_inlay:set_color(rt.color_darken(base_color, 0.1))
            slot.frame:set_color(rt.color_darken(base_color, 0.25))
            slot.frame:set_is_outline(true)
        end
    end

    self._frame:realize()
end

--- @override
function mn.Slots:size_allocate(x, y, width, height)
    local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale
    local slot_h = slot_w
    local m = rt.settings.margin_unit
    local n_slots_total = self._n_equip_slots + self._n_consumable_slots + self._n_move_slots
    local slot_m = (width - (n_slots_total * slot_w)) / (n_slots_total + 1)
    local inlay_factor = 0.7

    local current_x, current_y = x + m + 0.5 * slot_m, y + m
    local radius = 0.5 * slot_w
    for i = 1, n_slots_total do
        local slot
        if i <= self._n_equip_slots then
            slot = self._equip_slots[i]
            slot.base:resize(current_x, current_y, slot_w, slot_h)
            slot.frame:resize(current_x, current_y, slot_w, slot_h)
        elseif i > self._n_equip_slots and i <= self._n_equip_slots + self._n_consumable_slots then
            slot = self._consumable_slots[i - self._n_equip_slots]
            local center_x, center_y = current_x + 0.5 * slot_w, current_y + 0.5 * slot_h
            local points = {}
            local n_sides = 6
            for i = 1, n_sides do
                local point_x, point_y = rt.translate_point_by_angle(center_x, center_y, radius * 1.1, rt.degrees_to_radians(i / n_sides * 360))
                table.insert(points, point_x)
                table.insert(points, point_y)
            end
            slot.base:resize(table.unpack(points))
            slot.frame:resize(table.unpack(points))
        else
            slot = self._move_slots[i - (self._n_equip_slots + self._n_consumable_slots)]

            slot.base:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * slot_w, 0.5 * slot_h)
            slot.frame:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * slot_w, 0.5 * slot_h)
        end

        slot.base_inlay:resize(current_x + 0.5 * slot_w, current_y + 0.5 * slot_w, 0.5 * inlay_factor * slot_w, 0.5 * inlay_factor * slot_w)
        current_x = current_x + slot_w + slot_m

        if current_x > x + width then
            current_x = x + m + 0.5 * slot_m
            current_y = current_y + slot_h + 0.5 * slot_m
        end
    end

    self._frame:fit_into(x, y, width, m + slot_h + m)
    self._frame_was_allocated = true
end

--- @override
function mn.Slots:draw()
    if self._is_realized ~= true then return end
    self._frame:draw()

    for table_n in range(
        {self._consumable_slots, self._n_consumable_slots},
        {self._equip_slots, self._n_equip_slots},
        {self._move_slots, self._n_move_slots}
    ) do
        for i = 1, table_n[2] do
            local entry = table_n[1][i]
            entry.base:draw()
            entry.base_inlay:draw()
            entry.frame:draw()
            if entry.sprite ~= nil then
                entry.sprite:draw()
            end
        end
    end
end

--- @override
function mn.Slots:measure()
    if self._frame_was_allocated == true then
        return self._frame:measure()
    else
        local slot_w = rt.settings.menu.slots.sprite_resolution * rt.settings.menu.slots.sprite_scale
        local m = rt.settings.margin_unit
        return 2 * m + slot_w * (self._n_equip_slots + self._n_consumable_slots), 2 * m + slot_w
    end
end


