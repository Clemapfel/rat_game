rt.settings.battle.consumable = {
    config_path = "assets/configs/consumables",
    name = "Item"
}

--- @class bt.ConsumableConfig
bt.ConsumableConfig = meta.new_type("ConsumableConfig", function(id)
    local out = bt.ConsumableConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.consumable.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.ConsumableConfig, {
            id = id,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.ConsumableConfig._atlas[id] = out
    end
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,
    restore_uses_after_battle = false,
    is_silent = false,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_gained = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_lost = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_turn_start = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_turn_end = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_battle_start = function(self, holder)

    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_battle_end = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = function(self, holder, value)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = function(self, holder, hp_lost)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = function(self, holder, receiver, value)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = function(self, holder, damage_taker, value)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = function(self, holder, gained_status)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, StatusProxy)
    on_status_lost = function(self, holder, lost_status)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = function(self, holder, gained_status)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = function(self, holder, lost_status)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_knocked_out = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_knocked_out_other = function(self, holder, knocked_out_entity)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_helped_up = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_helped_up_other = function(self, holder, helped_up_entity)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_killed = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_killed_other = function(self, holder, killed_entity)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_revived = function(self, holder)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_revived_other = function(self, holder, revived_entity)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_swap = function(self, holder, entity_at_old_position)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, MoveProxy, Table<EntityProxy>)
    on_move_used = function(self, holder, move, targets)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = function(self, holder, move)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_consumed = function(self, holder, other_consumable)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_gained = function(self, holder, other_consumable)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_lost = function(self, holder, other_consumable)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_disabled = function(self, holder, other_consumable)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EntityProxy)
    on_entity_spawned = function(self, holder, other_entity)
        return nil
    end,

    -- (ConsumableProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = function(self, holder, equip)
        return nil
    end,

    description = rt.Translation.battle.consumable_default_description,
    flavor_text = rt.Translation.battle.consumable_default_flavor_text,
    sprite_id = "",
    sprite_index = 1
})
bt.ConsumableConfig._atlas = {}

--- @brief
function bt.ConsumableConfig:realize()
    if self._is_realized == true then return end

    local functions = {
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
        "on_knocked_out_other",
        "on_helped_up",
        "on_helped_up_other",
        "on_killed",
        "on_killed_other",
        "on_revived",
        "on_revived_other",
        "on_swap",
        "on_move_used",
        "on_move_disabled",
        "on_gained",
        "on_lost",
        "on_consumable_consumed",
        "on_consumable_gained",
        "on_consumable_lost",
        "on_consumable_disabled",
        "on_entity_spawned",
        "on_equip_disabled",
        "on_battle_start",
        "on_battle_end",
        "on_knocked_out_other"
    }

    local template = {
        id = rt.STRING,
        name = rt.STRING,
        description = rt.STRING,
        flavor_text = rt.STRING,
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
    self.see_also = {}
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.ConsumableConfig:get_id()
    return self.id
end

--- @brief
function bt.ConsumableConfig:get_name()
    return self.name
end

--- @brief
function bt.ConsumableConfig:get_max_n_uses()
    return self.max_n_uses
end

--- @brief
function bt.ConsumableConfig:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.ConsumableConfig:get_is_silent()
    return self.is_silent
end

--- @brief
function bt.ConsumableConfig:get_description()
    return self.description
end

--- @brief
function bt.ConsumableConfig:get_flavor_text()
    return self.flavor_text
end

