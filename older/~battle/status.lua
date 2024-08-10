rt.settings.battle.status = {
    config_path = "battle/configs/status"
}

--- @class bt.Status
--- @brief cached instancing, moves with the same ID will always return the same instance
--- @field id String
--- @field name String
--- @field attack_offset Unsigned
--- @field defense_offset Unsigned
bt.Status = meta.new_type("Status", function(id)
    local out = bt.Status._atlas[id]
    if out == nil then
        local path = rt.settings.battle.status.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Status, {
            id = id,
            name = "UNINITIALIZED STATUS @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Status._atlas[id] = out
    end
    return out
end, {
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

    -- (StatusInterface, EntityInterface) -> nil
    on_gained = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    -- (StatusInterface, EntityInterface) -> nil
    on_lost = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    on_turn_start = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    on_turn_end = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    on_battle_end = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    -- (StatusInterface, EntityInterface, Unsigned) -> nil
    on_healing_received = function(self, afflicted, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_number(value)
        return nil
    end,

    -- (StatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed = function(self, afflicted, receiver, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(receiver)
        meta.assert_number(value)
        return nil
    end,

    -- (StatusInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken = function(self, afflicted, hp_lost)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_number(hp_lost)
        return nil
    end,

    -- (StatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt = function(self, afflicted, damage_taker, value)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(value)
        return nil
    end,

    -- (StatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(gained_status)
        return nil
    end,

    -- (StatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(lost_status)
        return nil
    end,

    -- (StatusInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_gained = function(self, afflicted, gained_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_global_status_interface(gained_status)
        return nil
    end,

    -- (StatusInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_lost = function(self, afflicted, lost_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_global_status_interface(lost_status)
        return nil
    end,

    -- (StatusInterface, EntityInterface) -> nil
    on_knocked_out = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    -- (StatusInterface, EntityInterface) -> nil
    on_helped_up = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    -- (StatusInterface, EntityInterface)
    on_killed = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    -- (StatusInterface, EntityInterface, EntityInterface) -> nil
    on_switch = function(self, afflicted, entity_at_old_position)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(entity_at_old_position)
        return nil
    end,

    -- (StatusInterface, EntityInterface, MoveInterface, Table<EntityInterface>)
    on_move_used= function(self, afflicted_user, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
        return nil
    end,

    -- (StatusInterface, EntityInterface, ConsumableInterface) -> nil
    on_consumable_consumed = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        return nil
    end,

    description = "",
    sprite_id = "status_ailment",
    sprite_index = 1
})
bt.Status._atlas = {}

--- @brief
function bt.Status:realize()
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
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Status:get_sprite_id()
    return self.sprite_id, self.sprite_index
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