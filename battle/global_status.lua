rt.settings.battle.global_status = {
    config_path = "battle/configs/global_status"
}

--- @class GlobalStatus
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.GlobalStatus = meta.new_type("GlobalStatus", function(id)
    local out = bt.GlobalStatus._atlas[id]
    if out == nil then
        local path = rt.settings.battle.global_status.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.GlobalStatus, {
            id = id,
            name = "UNINITIALIZED GLOBAL_STATUS @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        bt.GlobalStatus._atlas[id] = out
    end
    return out
end, {
    max_duration = POSITIVE_INFINITY,
    is_silent = false,

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_gained = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_lost = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    on_turn_start = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    on_turn_end = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    on_battle_end = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, Unsigned) -> nil
    on_healing_received = function(self, entity, hp_gained)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(entity)
        meta.assert_number(hp_gained)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed = function(self, healing_performer, healing_receiver, hp_gained)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(healing_performer)
        meta.assert_entity_interface(healing_receiver)
        meta.assert_number(hp_gained)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken = function(self, entity, hp_lost)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(entity)
        meta.assert_number(hp_lost)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt = function(self, damage_dealer, damage_taker, value)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(value)
        return nil
    end,
    
    -- (GlobalStatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(gained_status)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(lost_status)
        return nil
    end,

    -- (GlobalStatusInterface, GlobalStatusInterface, Table<Entity>) -> nil
    on_global_status_gained = function(self, gained_status, entities)
        meta.assert_global_status_interface(self)
        meta.assert_global_status_interface(gained_status)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        return nil
    end,

    -- (GlobalStatusInterface, GlobalStatusInterface, Table<Entity>) -> nil
    on_global_status_lost = function(self, lost_status, entities)
        meta.assert_global_status_interface(self)
        meta.assert_global_status_interface(lost_status)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_knocked_out = function(self, knocked_out_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(knocked_out_entity)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_helped_up = function(self, helped_up_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(helped_up_entity)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_killed = function(self, killed_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(killed_entity)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, EntityInterface) -> nil
    on_switch = function(self, switched_entity, entity_at_old_position)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(switched_entity)
        meta.assert_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, stance_changer, old_stance, new_stance)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(stance_changer)
        meta.assert_stance_interface(old_stance)
        meta.assert_stance_interface(new_stance)
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, MoveInterface, Table<EntityInterface>) -> nil
    on_move_used= function(self, move_user, move, targets)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(move_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
        return nil
    end,

    -- (GlobalStatusInterface, EntityInterface, ConsumableInterface)
    on_consumable_consumed = function(self, holder, consumable)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(consumable)
        return nil
    end,

    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.GlobalStatus._atlas = {}

--- @brief
function bt.GlobalStatus:realize()
    if self._is_realized == true then return end

    local functions = {
        "on_gained",
        "on_lost",
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
        "on_consumable_consumed"
    }

    local template = {
        description = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        id = rt.STRING,
        name = rt.STRING,
        max_duration = rt.UNSIGNED,
        is_silent = rt.BOOLEAN
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
function bt.GlobalStatus:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.GlobalStatus:get_id()
    return self.id
end

--- @brief
function bt.GlobalStatus:get_name()
    return self.name
end

--- @brief
function bt.GlobalStatus:get_is_silent()
    return self.is_silent
end

--- @brief
function bt.GlobalStatus:get_max_duration()
    return self.max_duration
end