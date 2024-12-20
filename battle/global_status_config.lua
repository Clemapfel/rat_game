rt.settings.battle.global_status = {
    config_path = "assets/configs/global_statuses"
}

--- @class bt.GlobalStatusConfig
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.GlobalStatusConfig = meta.new_type("GlobalStatus", function(id)
    local out = bt.GlobalStatusConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.global_status.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.GlobalStatusConfig, {
            id = id,
            name = "UNINITIALIZED GLOBAL_STATUS @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        bt.GlobalStatusConfig._atlas[id] = out
    end
    return out
end, {
    max_duration = POSITIVE_INFINITY,

    description = rt.Translation.battle.global_status_default_description,
    flavor_text = rt.Translation.battle.global_status_default_flavor_text,
    see_also = {},

    sprite_id = "",
    sprite_index = 1,
    animation_id = "GLOBAL_STATUS_GAINED",

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_gained = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_lost = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_turn_start = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_turn_end = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_battle_start = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_battle_end = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = function(self, entity, hp_gained)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = function(self, healing_performer, healing_receiver, hp_gained)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = function(self, entity, hp_lost)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = function(self, damage_dealer, damage_taker, value)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = function(self, afflicted, gained_status)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_lost = function(self, afflicted, lost_status)
        return nil
    end,

    -- (GlobalStatusProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = function(self, gained_status)
        return nil
    end,

    -- (GlobalStatusProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = function(self, lost_status)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_knocked_out = function(self, knocked_out_entity, knocked_out_by_entity)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_helped_up = function(self, helped_up_entity, helped_up_by_entity)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_killed = function(self, killed_entity, killed_by_entity)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_revived = function(self, killed_entity, revived_by_entity)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy) -> nil
    on_swap = function(self, switched_entity, entity_at_old_position)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, MoveProxy, Table<EntityProxy>) -> nil
    on_move_used = function(self, move_user, move, targets)
        return nil
    end,

    -- (GlobalStatusproxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = function(self, move_user, move)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_consumed = function(self, holder, consumable)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_gained = function(self, holder, consumable)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_lost = function(self, holder, consumable)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_disabled = function(self, holder, consumable)
        return nil
    end,

    -- (GlobalStatusProxy, Table<EntityProxy>)
    on_entity_spawned = function(self, entities)
        return nil
    end,

    -- (GlobalStatusProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = function(self, holder, equip)
        return nil
    end
})
bt.GlobalStatusConfig._atlas = {}

--- @brief
function bt.GlobalStatusConfig:realize()
    if self._is_realized == true then return end

    local functions = {
        "on_gained",
        "on_lost",
        "on_turn_start",
        "on_turn_end",
        "on_hp_gained",
        "on_healing_performed",
        "on_hp_lost",
        "on_damage_dealt",
        "on_status_gained",
        "on_status_lost",
        "on_global_status_gained",
        "on_global_status_lost",
        "on_knocked_out",
        "on_helped_up",
        "on_killed",
        "on_revived",
        "on_swap",
        "on_move_used",
        "on_move_disabled",
        "on_consumable_consumed",
        "on_consumable_gained",
        "on_consumable_lost",
        "on_consumable_disabled",
        "on_entity_spawned",
        "on_equip_disabled",
        "on_battle_start",
        "on_battle_end"
    }

    local template = {
        description = rt.STRING,
        flavor_text = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        id = rt.STRING,
        name = rt.STRING,
        max_duration = rt.UNSIGNED
    }

    for key in values(functions) do
        self[key] = nil  -- set functions to nil if unassigned
        template[key] = rt.FUNCTION
    end

    meta.set_is_mutable(self, true)
    self.see_also = {}
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.GlobalStatusConfig:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.GlobalStatusConfig:get_id()
    return self.id
end

--- @brief
function bt.GlobalStatusConfig:get_name()
    return self.name
end

--- @brief
function bt.GlobalStatusConfig:get_max_duration()
    return self.max_duration
end

--- @brief
function bt.GlobalStatusConfig:get_description()
    return self.description
end

--- @brief
function bt.GlobalStatusConfig:get_flavor_text()
    return self.flavor_text
end