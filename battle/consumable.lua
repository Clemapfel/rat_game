rt.settings.battle.consumable = {
    config_path = "battle/configs/consumables"
}

--- @class bt.Consumable
bt.Consumable = meta.new_type("Consumable", function(id)
    local out = bt.Consumable._atlas[id]
    if out == nil then
        local path = rt.settings.battle.consumable.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Consumable, {
            id = id,
            name = "UNINITIALIZED CONSUMABLE @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Consumable._atlas[id] = out
    end
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,
    restore_uses_after_battle = false,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_turn_start = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    on_turn_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    on_battle_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, Unsigned) -> nil
    on_healing_received = function(self, holder, value)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_number(value)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed = function(self, holder, receiver, value)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(receiver)
        meta.assert_number(value)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken = function(self, holder, hp_lost)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_number(hp_lost)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt = function(self, holder, damage_taker, value)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(value)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(gained_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, StatusInterface)
    on_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(lost_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(gained_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(lost_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_knocked_out = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_helped_up = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_killed = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, EntityInterface) -> nil
    on_switch = function(self, holder, entity_at_old_position)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(entity_at_old_position)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, MoveInterface, Table<EntityInterface>)
    on_move_used= function(self, holding_user, move, targets)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holding_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, ConsumableInterface)
    on_consumable_consumed = function(self, holder, other_consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(other_consumable)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, ConsumableInterface)
    on_consumable_gained = function(self, holder, other_consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(other_consumable)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, ConsumableInterface)
    on_consumable_lost = function(self, holder, other_consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(other_consumable)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface)
    on_entity_spawned = function(self, holder, other_consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.Consumable._atlas = {}

--- @brief
function bt.Consumable:realize()
    if self._is_realized == true then return end

    local functions = {
        "on_turn_start",
        "on_turn_end",
        "on_healing_received",
        "on_healing_performed",
        "on_damage_taken",
        "on_damage_dealt",
        "on_status_gained",
        "on_status_lost",
        "on_global_status_gained",
        "on_global_status_lost",
        "on_knocked_out",
        "on_helped_up",
        "on_killed",
        "on_switch",
        "on_move_used",
        "on_consumable_consumed",
        "on_consumable_gained",
        "on_consumable_lost",
        "on_entity_spawned"
    }

    local template = {
        id = rt.STRING,
        name = rt.STRING,
        description = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        max_n_uses = rt.UNSIGNED,
        is_silent = rt.BOOLEAN,
    }

    for key in values(functions) do
        self[key] = nil  -- set functions to nil if unassigned
        template[key] = rt.FUNCTION
    end

    meta.set_is_mutable(self, true)
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Consumable:get_id()
    return self.id
end

--- @brief
function bt.Consumable:get_name()
    return self.name
end

--- @brief
function bt.Consumable:get_max_n_uses()
    return self.max_n_uses
end

--- @brief
function bt.Consumable:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.Consumable:get_is_silent()
    return self.is_silent
end
