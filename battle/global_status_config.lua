rt.settings.battle.global_status = {
    config_path = "assets/configs/global_statuses"
}

--- @class bt.GlobalStatusConfig
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.GlobalStatusConfig = meta.new_type("GlobalStatus", function(id)
    meta.assert_string(id)
    local out = bt.GlobalStatusConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.global_status.config_path .. "/" .. id .. ".lua"
        local config = bt.GlobalStatusConfig.load_config(path)
        config.id = id
        config.see_also = {}
        out = meta.new(bt.GlobalStatusConfig, config)
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
    on_gained = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_lost = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_turn_start = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_turn_end = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_battle_start = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>) -> nil
    on_battle_end = nil,

    -- (GlobalStatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = nil,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = nil,

    -- (GlobalStatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = nil,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = nil,

    -- (GlobalStatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = nil,

    -- (GlobalStatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_lost = nil,

    -- (GlobalStatusProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = nil,

    -- (GlobalStatusProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = nil,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_knocked_out = nil,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_helped_up = nil,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_killed = nil,

    -- (GlobalStatusProxy, EntityProxy) -> nil
    on_revived = nil,

    -- (GlobalStatusProxy, EntityProxy, EntityProxy) -> nil
    on_swap = nil,

    -- (GlobalStatusProxy, EntityProxy, MoveProxy, Table<EntityProxy>) -> nil
    on_move_used = nil,

    -- (GlobalStatusproxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = nil,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_consumed = nil,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_gained = nil,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy)
    on_consumable_lost = nil,

    -- (GlobalStatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_disabled = nil,

    -- (GlobalStatusProxy, Table<EntityProxy>)
    on_entity_spawned = nil,

    -- (GlobalStatusProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = nil
})
meta.make_immutable(bt.GlobalStatusConfig)
bt.GlobalStatusConfig._atlas = {}

--- @brief
function bt.GlobalStatusConfig.load_config(path)
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
        template[key] = rt.FUNCTION
    end

    return rt.load_config(path, template)
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