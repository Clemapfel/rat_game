--- @class mn.EntityPage
mn.EntityPage = meta.new_type("EntityPage", rt.Widget, function(entity)
    return meta.new(mn.EntityPage, {
        _entity = entity,
        _info = mn.EntityInfo(entity),
        _slots = {}
    })
end)

--- @override
function mn.EntityPage:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._info:realize()
end

--- @override
function mn.EntityPage:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit

end

--- @override
function mn.EntityPage:draw()
    self._info:draw()
end

--- @brief
function mn.EntityPage:preview_equip(equip_slot_i, equip)
    local old = {
        hp_base = self._entity:get_hp_base(),
        attack_base = self._entity:get_attack_base(),
        defense_base = self._entity:get_defense_base(),
        speed_base = self._entity:get_speed_base()
    }

    local new = self._entity:preview_equip(equip_slot_i, equip)
    self._info:set_preview_values(
        ternary(new.hp_base ~= old.hp_base, new.hp_base, nil),
        ternary(new.attack_base ~= old.attack_base, new.attack_base, nil),
        ternary(new.defense_base ~= old.defense_base, new.defense_base, nil),
        ternary(new.speed_base ~= old.speed_base, new.speed_base, nil)
    )
end