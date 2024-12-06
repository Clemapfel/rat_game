rt.settings.battle.status = {
    config_path = "assets/configs/statuses",
    default_animation_id = "STATUS_GAINED",
}

--- @class bt.Status
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.Status = meta.new_type("Status", function(id)
    local out = bt.Status._atlas[id]
    if out == nil then
        local path = rt.settings.battle.status.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Status, {
            id = id,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Status._atlas[id] = out
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
    is_silent = false,

    -- (StatusProxy, EntityProxy) -> nil
    on_gained = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_lost = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_already_present = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_turn_start = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_turn_end = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_battle_end = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_gained = function(self, afflicted, value)
        return nil
    end,

    -- (StatusProxy, EntityProxy, Unsigned) -> nil
    on_hp_lost = function(self, afflicted, hp_lost)
        return nil
    end,

    -- (StatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_healing_performed = function(self, afflicted, receiver, value)
        return nil
    end,

    -- (StatusProxy, EntityProxy, EntityProxy, Unsigned) -> nil
    on_damage_dealt = function(self, afflicted, damage_taker, value)
        return nil
    end,

    -- (StatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_gained = function(self, afflicted, gained_status)
        return nil
    end,

    -- (StatusProxy, EntityProxy, StatusProxy) -> nil
    on_status_lost = function(self, afflicted, lost_status)
        return nil
    end,

    -- (StatusProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_gained = function(self, afflicted, gained_status)
        return nil
    end,

    -- (StatusProxy, EntityProxy, GlobalStatusProxy) -> nil
    on_global_status_lost = function(self, afflicted, lost_status)
        return nil
    end,

    -- (StatusProxy, EntityProxy) -> nil
    on_knocked_out = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy)
    on_killed = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy)
    on_revived = function(self, afflicted)
        return nil
    end,

    -- (StatusProxy, EntityProxy, EntityProxy) -> nil
    on_swap = function(self, afflicted, entity_at_old_position)
        return nil
    end,

    -- (StatusProxy, EntityProxy, MoveProxy, Table<EntityProxy>) -> nil
    on_move_used = function(self, afflicted_user, move, targets)
        return nil
    end,

    -- (StatusProxy, EntityProxy, MoveProxy) -> nil
    on_move_disabled = function(self, afflicted, move)

    end,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_consumed = function(self, afflicted, consumable)
        return nil
    end,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_gained = function(self, afflicted, consumable)
        return nil
    end,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_lost = function(self, afflicted, consumable)
        return nil
    end,

    -- (StatusProxy, EntityProxy, ConsumableProxy) -> nil
    on_consumable_disabled = function(self, afflicted, consumable)
        return nil
    end,

    -- (StatusProxy, EntityProxy)
    on_entity_spawned = function(self, afflicted)
    end,

    -- (StatusProxy, EntityProxy, EquipProxy) -> nil
    on_equip_disabled = function(self, afflicted, equip)
        return nil
    end
})
bt.Status._atlas = {}

--- @brief
function bt.Status:realize()
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
        "on_equip_disabled"
    }

    local template = {
        description = rt.STRING,
        flavor_text = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },
        animation_id = rt.STRING,
        name = rt.STRING,
        max_duration = rt.UNSIGNED,
        is_silent = rt.BOOLEAN,
        is_stun = rt.BOOLEAN
    }

    for key in values(functions) do
        self[key] = nil  -- set functions to nil if unassigned
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

    meta.set_is_mutable(self, true)
    self.see_also = {}
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Status:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.Status:get_animation_id()
    return self.animation_id
end

--- @brief
function bt.Status:get_id()
    return self.id
end

--- @brief
function bt.Status:get_name()
    return self.name
end

--- @brief
function bt.Status:get_max_duration()
    return self.max_duration
end

--- @brief
function bt.Status:get_is_silent()
    return self.is_silent
end

--- @brief
function bt.Status:get_description()
    return self.description
end

--- @brief
function bt.Status:get_flavor_text()
    return self.flavor_text
end

--- @brief
function bt.Status:get_is_stun()
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
    bt.Status["get_" .. which] = function(self)
        return self[which]
    end
end