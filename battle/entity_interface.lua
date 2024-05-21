--- @class bt.EntityInterface
bt.EntityInterface = {
    --- @brief
    get_name = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_name()
    end,

    --- @brief
    get_formatted_name = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).scene:format_name(getmetatable(self).original)
    end,

    --- @brief
    get_id = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_id()
    end,

    --- @brief
    get_hp_current = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_hp_current()
    end,

    --- @brief
    get_hp_base = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_hp_base()
    end,

    --- @brief
    get_priority = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_priority()
    end,

    --- @brief
    get_is_stunned = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_is_stunned()
    end,

    --- @brief
    get_is_knocked_out = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_is_knocked_out()
    end,

    --- @brief
    get_is_dead = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_is_dead()
    end,

    --- @brief
    get_is_alive = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_is_alive()
    end,

    --- @brief
    get_is_enemy = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).original:get_is_enemy()
    end,

    --- @brief
    get_is_ally = function(self)
        meta.assert_entity_interface(self)
        return not self:get_is_enemy()
    end,

    --- @brief
    get_is_enemy_of = function(self, other)
        meta.assert_entity_interface(self)
        meta.assert_entity_interface(other)
        return self:get_is_enemy() ~= other:get_is_enemy()
    end,

    --- @brief
    get_is_ally_of = function(self, other)
        meta.assert_entity_interface(self)
        meta.assert_entity_interface(other)
        return self:get_is_enemy() == other:get_is_enemy()
    end,

    --- @brief
    increase_hp = function(self, value)
        meta.assert_entity_interface(self)
        meta.assert_number(value)
        getmetatable(self).scene:increase_hp(getmetatable(self).original, value)
    end,

    --- @brief
    reduce_hp = function(self, value)
        meta.assert_entity_interface(self)
        meta.assert_number(value)
        getmetatable(self).scene:reduce_hp(getmetatable(self).original, value)
    end,

    --- @brief
    help_up = function(self)
        meta.assert_entity_interface(self)
        getmetatable(self).scene:help_up(getmetatable(self).original)
    end,

    --- @brief
    kill = function(self)
        meta.assert_entity_interface(self)
        getmetatable(self).scene:kill(getmetatable(self).original)
    end,

    --- @brief
    knock_out = function(self)
        meta.assert_entity_interface(self)
        getmetatable(self).scene:knock_out(getmetatable(self).original)
    end,

    --- @brief
    switch = function(self, other)
        meta.assert_entity_interface(self)
        meta.assert_entity_interface(other)
        getmetatable(self).scene:switch(getmetatable(self).original, getmetatable(other).original)
    end,

    --- @brief
    has_status = function(self, status)
        meta.assert_entity_interface(self)
        meta.assert_status_interface(status)
        return getmetatable(self).original:has_status(getmetatable(status).original)
    end,

    --- @brief
    get_status_n_turns_elapsed = function(self, status)
        meta.assert_entity_interface(self)
        meta.assert_status_interface(status)
        return getmetatable(self).original:get_status_n_turns_elapsed(getmetatable(status).original)
    end,

    --- @brief
    get_status_n_turns_left = function(self, status)
        meta.assert_entity_interface(self)
        meta.assert_status_interface(status)
        return getmetatable(self).original:get_status_n_turns_left(getmetatable(status).original)
    end,

    --- @brief
    add_status = function(self, status)
        meta.assert_entity_interface(self)
        meta.assert_status_interface(status)
        getmetatable(self).scene:add_status(getmetatable(self).original, getmetatable(status).original)
    end,

    --- @brief
    remove_status = function(self, status)
        meta.assert_entity_interface(self)
        meta.assert_status_interface(status)
        getmetatable(self).scene:remove_status(getmetatable(self).original, getmetatable(status).original)
    end,

    --- @brief
    list_statuses = function(self)
        meta.assert_entity_interface(self)
        local out = {}
        local scene = getmetatable(self).scene
        local entity = getmetatable(self).original
        for status in values(entity:list_statuses()) do
            table.insert(out, bt.StatusInterface(scene, entity, status))
        end
        return out
    end,

    --- @brief
    has_equip = function(self, equip)
        meta.assert_entity_interface(self)
        meta.assert_equip_interface(equip)
        return getmetatable(self).original:has_equip(getmetatable(equip).original)
    end,

    --- @brief
    list_equips = function(self)
        meta.assert_entity_interface(self)
        local out = {}
        local scene = getmetatable(self).scene
        local entity = getmetatable(self).original
        for equip in values(entity:list_equips()) do
            table.insert(out, bt.EquipInterface(scene, equip))
        end
        return out
    end,

    --- @brief
    consume = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        getmetatable(self).scene:consume(getmetatable(self).original, getmetatable(consumable).original)
    end,

    --- @brief
    has_consumable = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        return getmetatable(self).original:has_consumable(getmetatable(consumable).original)
    end,

    --- @brief
    get_consumable_n_consumed = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        return getmetatable(self).original:get_consumable_n_consumed(getmetatable(consumable).original)
    end,

    --- @brief
    get_consumable_n_uses_left = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        return getmetatable(self).original:get_consumable_n_uses_left(getmetatable(consumable).original)
    end,

    --- @brief
    add_consumable = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        rt.error("TODO")
        getmetatable(self).scene:add_consumable(getmetatable(self).original, getmetatable(consumable).original)
    end,

    --- @brief
    remove_consumable = function(self, consumable)
        meta.assert_entity_interface(self)
        meta.assert_consumable_interface(consumable)
        getmetatable(self).scene:remove_consumable(getmetatable(self).original, getmetatable(consumable).original)
    end,

    --- @brief
    list_consumables = function(self)
        meta.assert_entity_interface(self)
        local out = {}
        local scene = getmetatable(self).scene
        local entity = getmetatable(self).original
        for consumable in values(entity:list_consumables()) do
            table.insert(out, bt.ConsumableInterface(scene, entity, consumable))
        end
        return out
    end,

    --- @brief
    has_move = function(self, move)
        meta.assert_entity_interface(self)
        meta.assert_move_interface(move)
        return getmetatable(self).original:has_move(getmetatable(move).original)
    end,

    --- @brief
    get_move_n_used = function(self, move)
        meta.assert_entity_interface(self)
        meta.assert_move_interface(move)
        return getmetatable(self).get_move_n_used:has_move(getmetatable(move).original)
    end,

    --- @brief
    get_move_n_uses_left = function(self, move)
        meta.assert_entity_interface(self)
        meta.assert_move_interface(move)
        return getmetatable(self).get_m_n_uses_left:has_move(getmetatable(move).original)
    end,

    --- @brief
    list_moves = function(self)
        meta.assert_entity_interface(self)
        local out = {}
        local scene = getmetatable(self).scene
        local entity = getmetatable(self).original
        for move in values(entity:list_moves()) do
            table.insert(out, bt.MoveInterface(scene, move))
        end
        return out
    end,

    --- @brief
    get_left_of = function(self)
        meta.assert_entity_interface(self)
        local scene = getmetatable(self).scene
        return bt.EntityInterface(scene, scene._state:get_left_of(getmetatable(self).original))
    end,

    --- @brief
    get_right_of = function(self)
        meta.assert_entity_interface(self)
        local scene = getmetatable(self).scene
        return bt.EntityInterface(scene, scene._state:get_right_of(getmetatable(self).original))
    end,

    --- @brief
    get_position = function(self)
        meta.assert_entity_interface(self)
        return getmetatable(self).scene._state:get_position(getmetatable(self).original)
    end,
}

bt.EntityInterface.get_hp = bt.EntityInterface.get_hp_current
for stat in range("attack", "defense", "speed") do
    --- @brief
    bt.EntityInterface["get_" .. stat] = function(self)
        local original = getmetatable(self).original
        return original["get_" .. stat](original)
    end

    --- @brief get base without modifiers
    bt.EntityInterface["get_" .. stat .. "_base_raw"] = function()
        local original = getmetatable(self).original
        return original["get_" .. stat .. "_base_raw"](original)
    end

    --- @brief get base
    bt.EntityInterface["get_" .. stat .. "_base"] = function()
        local original = getmetatable(self).original
        return original["get_" .. stat .. "_base_raw"](original)
    end
end

--- @brief ctor
setmetatable(bt.EntityInterface, {
    __call = function(_, scene, entity)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(entity, bt.Entity)

        local self, metatable = {}, {}
        setmetatable(self, metatable)

        metatable.type = "bt.EntityInterface"
        metatable.scene = scene
        metatable.original = entity

        for key, value in pairs(bt.EntityInterface) do
            self[key] = value
        end

        local valid_fields = {
            id = true,
            name = true,
            is_enemy = true
        }

        metatable.__index = function(self, key)
            if valid_fields[key] == true then
                return self["get_" .. key](self)
            else
                rt.warning("In bt.GlobalStatusInterface:__index: trying to access property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
                return nil
            end
        end

        metatable.__newindex = function(self, key, value)
            rt.warning("In bt.GlobalStatusInterface:__newindex: trying to set property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
            return nil
        end

        return self
    end
})