rt.settings.battle.status = {
    config_path = "assets/configs/statuses",
    default_animation_id = "STATUS_GAINED",
}

--- @class bt.StatusConfig
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.StatusConfig = meta.new_type("StatusConfig", function(id)
    meta.assert_string(id)
    local out = bt.StatusConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.status.config_path .. "/" .. id .. ".lua"
        local config = bt.StatusConfig.load_config(path)
        config.id = id
        config.see_also = {}
        out = meta.new(bt.StatusConfig, config)
        bt.StatusConfig._atlas[id] = out
    end
    return out
end, {
    name = "",
    description = rt.Translation.battle.status_default_description,
    flavor_text = rt.Translation.battle.status_default_flavor_text,
    see_also = {},

    sprite_id = "status_ailment",
    sprite_index = 1,
    animation_id = rt.settings.battle.status.default_animation_id,

    attack_offset = 0,   -- Signed
    defense_offset = 0,  -- Signed
    speed_offset = 0,    -- Signed

    attack_factor = 1,   -- Float >= 0
    defense_factor = 1,  -- Float >= 0
    speed_factor = 1,    -- Float >= 0

    damage_dealt_factor = 1,      -- Float >= 0
    damage_received_factor = 1,   -- Float >= 0
    healing_performed_factor = 1, -- Float >= 0
    healing_received_factor = 1,  -- Float >= 0

    damage_dealt_offset = 0,      -- Signed
    damage_received_offset = 0,   -- Signed
    healing_performed_offset = 0, -- Signed
    healing_received_offset = 0,  -- Signed

    is_stun = false, -- Boolean

    max_duration = POSITIVE_INFINITY,

    -- (StatusProxy, EntityProxy) -> nil
    on_gained = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_lost = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_already_present = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_turn_start = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_turn_end = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_battle_start = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_battle_end = nil,

    -- (StatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = nil,

    -- (StatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = nil,

    -- (StatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = nil,

    -- (StatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = nil,

    -- (StatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = nil,

    -- (StatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_lost = nil,

    -- (StatusProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = nil,

    -- (StatusProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_knocked_out = nil,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_knocked_out_other = nil,

    -- (StatusProxy, EntityProxy) -> nil
    on_helped_up = nil,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_helped_up_other = nil,

    -- (StatusProxy, EntityProxy)
    on_killed = nil,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_killed_other = nil,

    -- (StatusProxy, EntityProxy)
    on_revived = nil,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_revived_other = nil,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_swap = nil,

    -- (StatusProxy, EntityProxy, MoveProxy, Table<EntityProxy>) -> nil
    on_move_used = nil,

    -- (StatusProxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = nil,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_consumed = nil,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_gained = nil,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_lost = nil,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_disabled = nil,

    -- (StatusProxy, EntityProxy)
    on_entity_spawned = nil,

    -- (StatusProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = nil
})

meta.make_immutable(bt.StatusConfig)
bt.StatusConfig._atlas = {}

--- @brief
function bt.StatusConfig.load_config(path)
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
        "on_consumable_consumed",
        "on_consumable_gained",
        "on_consumable_lost",
        "on_consumable_disabled",
        "on_entity_spawned",
        "on_equip_disabled",
        "on_battle_start",
        "on_battle_end",
    }

    local template = {
        description = rt.STRING,
        flavor_text = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        animation_id = rt.STRING,
        name = rt.STRING,
        max_duration = rt.UNSIGNED,
        is_stun = rt.BOOLEAN
    }

    for key in values(functions) do
        template[key] = rt.FUNCTION
    end

    for which in  range(
        "attack",
        "defense",
        "speed",
        "damage_dealt",
        "damage_received",
        "healing_performed",
        "healing_received"
    ) do
        template[which .. "_offset"] = "Signed"
        template[which .. "_factor"] = "Float"
    end

    return rt.load_config(path, template)
end

--- @brief
function bt.StatusConfig:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.StatusConfig:get_animation_id()
    return self.animation_id
end

--- @brief
function bt.StatusConfig:get_id()
    return self.id
end

--- @brief
function bt.StatusConfig:get_name()
    return self.name
end

--- @brief
function bt.StatusConfig:get_max_duration()
    return self.max_duration
end

--- @brief
function bt.StatusConfig:get_description()
    return self.description
end

--- @brief
function bt.StatusConfig:get_flavor_text()
    return self.flavor_text
end

--- @brief
function bt.StatusConfig:get_is_stun()
    return self.is_stun
end

for which in range(
    "attack_offset",
    "defense_offset",
    "speed_offset",
    "attack_factor",
    "defense_factor",
    "speed_factor",

    "damage_dealt_factor",
    "damage_received_factor",
    "healing_performed_factor",
    "healing_received_factor",

    "damage_dealt_offset",
    "damage_received_offset",
    "healing_performed_offset",
    "healing_received_offset",

    "is_stun",
    "max_duration"
) do
    bt.StatusConfig["get_" .. which] = function(self)
        return self[which]
    end
end