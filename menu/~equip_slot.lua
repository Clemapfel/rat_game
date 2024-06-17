rt.settings.menu.equip_slot = {
    sprite_path = "assets/sprites/menu_type_sprites",
    sprite_ids = {
        [bt.EquipType.WEAPON] = "weapon",
        [bt.EquipType.CLOTHING] = "clothing",
        [bt.EquipType.TRINKET] = "trinket",
        [bt.EquipType.UNKNOWN] = "unknown"
    },
    sprite_factor = 3
}

--- @class mn.Slot
mn.Slot = meta.new_type("Slot", rt.Widget, function(type_sprite_name, type_sprite_index)
    type = which(type, bt.EquipType.UNKNOWN)
    return meta.new(mn.Slot, {
        _equip = {},
        _equip_sprite = {},
        _type = type,
        _base = rt.Spacer(),
        _frame = rt.Frame(),
        _type_sprite = {}
    })
end)

--- @brief
function mn.Slot:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()
    self._base:realize()
    self._frame:set_child(self._base)

    local sprite_name = rt.settings.menu.equip_slot.sprite_path
    if self._equip:get_type() == rt.EquipType.WEAPON then
        self._type_sprite = rt.Sprite(sprite_name, rt.settings.menu.equip_slot.sprite_ids[bt.EquipType.WEAPON])
    elseif self._equip:get_type() == rt.EquipType.CLOTHING then
        self._type_sprite = rt.Sprite(sprite_name, rt.settings.menu.equip_slot.sprite_ids[bt.EquipType.CLOTHING])
    elseif self._equip:get_type() == rt.EquipType.TRINKET then
        self._type_sprite = rt.Sprite(sprite_name, rt.settings.menu.equip_slot.sprite_ids[bt.EquipType.TRINKET])
    elseif self._equip:get_type() == rt.EquipType.UNKNOWN then
        self._type_sprite = rt.Sprite(sprite_name, rt.settings.menu.equip_slot.sprite_ids[bt.EquipType.UNKNOWN])
    end

    if meta.isa(self._equip, bt.Equip) then
        self._equip_sprite:realize()
    end
end

--- @brief
function mn.Slot:size_allocate(x, y, width, height)
    self._frame:fit_into(x, y, width, height)
    
    local thickness = self._frame:get_thickness()
    local x, y = x + thickness, y + thickness
    local sprite_w, sprite_h = self._type_sprite:measure()

    self._type_sprite:fit_into(x + 0.5 * width - 0.5 * sprite_w, y + 0.5 * height - 0.5 * sprite_h)
end

--- @brief
function mn.Slot:draw()
    self._frame:draw()
    rt.graphics.translate(self._type_sprite_position_x, self._type_sprite_position_y)
    self._type_sprite:draw()
    rt.graphics.translate(-1 * self._type_sprite_position_x, -1 * self._type_sprite_position_y)
end

--- @brief
function mn.Slot:set_equip(equip)
    self.
end

--- @brief
function mn.Slot:set_selection_state(state)

end