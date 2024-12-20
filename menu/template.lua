--- @class mn.Template
mn.Template = meta.new_type("InventoryTemplate", function(state, id)
    meta.assert_isa(state, rt.GameState)
    meta.assert_string(id)
    return meta.new(mn.Template, {
        _id = id,
        _state = state
    })
end)

--- @brief
function mn.Template:get_id()
    return self._id
end

--- @brief
function mn.Template:get_name()
    return self._state:template_get_name(self._id)
end

--- @brief
function mn.Template:get_date()
    return self._state:template_get_date(self._id)
end

--- @brief
function mn.Template:list_party()
    return self._state:template_list_party(self._id)
end

--- @brief
--- @return Unsigned, Table<bt.MoveConfig>
function mn.Template:list_move_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    return self._state:template_list_move_slots(self._id, entity)
end

--- @brief
--- @return Unsigned, Table<bt.ConsumableConfig>
function mn.Template:list_consumable_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    return self._state:template_list_consumable_slots(self._id, entity)
end

--- @brief
--- @return Unsigned, Table<bt.EquipConfig>
function mn.Template:list_equip_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    return self._state:template_list_equip_slots(self._id, entity)
end

--- @brief
function mn.Template:get_creation_date()
    return self._state:template_get_date(self._id)
end

--- @brief
function mn.Template:get_sprite_id()
    return "moves", "DEBUG_MOVE"
end
