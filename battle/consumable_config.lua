rt.settings.battle.consumable = {
    config_path = "assets/configs/consumables",
    name = "Item"
}

--- @class bt.ConsumableConfig
bt.ConsumableConfig = meta.new_type("ConsumableConfig", function(id)
    meta.assert_string(id)
    local out = bt.ConsumableConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.consumable.config_path .. "/" .. id .. ".lua"
        local config = bt.ConsumableConfig.load_config(path)
        config.id = id
        config.see_also = {}
        out = meta.new(bt.ConsumableConfig, config)
        bt.ConsumableConfig._atlas[id] = out
    end
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,
    restore_uses_after_battle = false,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_gained = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_lost = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_turn_start = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_turn_end = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_battle_start = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_battle_end = nil,

    -- (ConsumableProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = nil,

    -- (ConsumableProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = nil,

    -- (ConsumableProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = nil,

    -- (ConsumableProxy, EntityProxy, StatusProxy)
    on_status_lost = nil,

    -- (ConsumableProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = nil,

    -- (ConsumableProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_knocked_out = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_knocked_out_other = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_helped_up = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_helped_up_other = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_killed = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_killed_other = nil,

    -- (ConsumableProxy, EntityProxy) -> nil
    on_revived = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_revived_other = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy) -> nil
    on_swap = nil,

    -- (ConsumableProxy, EntityProxy, MoveProxy, Table<EntityProxy>)
    on_move_used = nil,

    -- (ConsumableProxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = nil,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_consumed = nil,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_gained = nil,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_lost = nil,

    -- (ConsumableProxy, EntityProxy, ConsumableProxy)
    on_consumable_disabled = nil,

    -- (ConsumableProxy, EntityProxy, EntityProxy)
    on_entity_spawned = nil,

    -- (ConsumableProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = nil,

    description = rt.Translation.battle.consumable_default_description,
    flavor_text = rt.Translation.battle.consumable_default_flavor_text,
    sprite_id = "",
    sprite_index = 1
})
meta.make_immutable(bt.ConsumableConfig)
bt.ConsumableConfig._atlas = {}

--- @brief
function bt.ConsumableConfig.load_config(path)
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
    }

    for key in values(functions) do
        template[key] = rt.FUNCTION
    end

    return rt.load_config(path, template)
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
function bt.ConsumableConfig:get_description()
    return self.description
end

--- @brief
function bt.ConsumableConfig:get_flavor_text()
    return self.flavor_text
end