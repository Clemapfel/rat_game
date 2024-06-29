--- @class mn.EntityPage
mn.EntityPage = meta.new_type("EntityPage", rt.Widget, function(entity)
    local out = meta.new(mn.EntityPage, {
        _entity = entity,
        _info = mn.EntityInfo(entity),
        _equip_slots = {},
        _consumable_slot = mn.ConsumableSlot()
    })

    local slot_types = entity:get_equip_slot_types()
    for type in values(slot_types) do
        table.insert(out._equip_slots, mn.EquipSlot(type))
    end
    return out
end)

--- @override
function mn.EntityPage:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._info:realize()
    for slot in values(self._equip_slots) do
        slot:realize()
    end
    self._consumable_slot:realize()
end

--- @override
function mn.EntityPage:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit

    local slot_w = self._equip_slots[1]:measure()
    local slot_h = slot_w
    local slot_x, slot_y = x, y + height - slot_h - m

    self._info:fit_into(x, y, width, height - 2 * m - slot_h)
    local current_x, current_y = x, slot_y
    for slot in values(self._equip_slots) do
        slot:fit_into(current_x, current_y, slot_w, slot_h)
        current_x = current_x + slot_w + m
    end
    self._consumable_slot:fit_into(current_x, current_y, slot_w, slot_h)
end

--- @override
function mn.EntityPage:draw()
    self._info:draw()
    for slot in values(self._equip_slots) do
        slot:draw()
    end
    self._consumable_slot:draw()
end

--- @brief
function mn.EntityPage:preview_equip(equip)
    local old
end