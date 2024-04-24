rt.settings.battle.status = {
    config_path = "battle/configs/status"
}

--- @class Status
--- @brief cached instancing, moves with the same ID will always return the same instance
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
    attack_offset = 0,
    defense_offset = 0,
    speed_offset = 0,

    attack_factor = 1,
    defense_factor = 1,
    speed_factor = 1,

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

    on_before_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return nil
    end,

    on_before_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(damage)
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

    on_killed = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        return nil
    end,

    on_switch = function(self, afflicted, entity_at_old_position)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, afflicted, old_stance, new_stance)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_stance_interface(old_stance)
        meta.assert_stance_interface(new_stance)
        return nil
    end,

    on_before_move = function(self, afflicted, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, afflicted, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return nil
    end,

    on_before_consumable = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        return nil
    end,

    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.Status._atlas = {}

--- @brief
function bt.Status:realize()
    if self._is_realized == true then return end

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Status:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    -- load properties if specified, assert correct type, use default if left unspecified
    local config = chunk()
    meta.set_is_mutable(self, true)

    local strings = {
        "name",
        "description"
    }

    for _, key in ipairs(strings) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_string(self[key])
    end

    local numbers = {
        "attack_offset",
        "defense_offset",
        "speed_offset",
        "attack_factor",
        "defense_factor",
        "speed_factor",
        "max_duration"
    }

    for key in values(numbers) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_number(self[key])
    end

    for factor in range(self.attack_factor, self.defense_factor, self.speed_factor) do
        if factor < 0 then
            rt.error("In bt.Status:realize: error when loading config at `" .. self._path .. "`: `attack_factor`, `defense_factor`, or `speed_factor` property < 0")
        end
    end

    local functions = {
        "on_gained",
        "on_lost",
        "on_turn_start",
        "on_turn_end",
        "on_battle_end",
        "on_before_damage_taken",
        "on_before_damage_dealt",
        "on_after_damage_taken",
        "on_after_damage_dealt",
        "on_status_gained",
        "on_status_lost",
        "on_global_status_gained",
        "on_global_status_lost",
        "on_knocked_out",
        "on_helped_up",
        "on_killed",
        "on_switch",
        "on_stance_changed",
        "on_before_move",
        "on_after_move",
        "on_before_consumable",
        "on_after_consumable"
    }

    for name in values(functions) do
        if config[name] ~= nil then
            self[name] = config[name]
            if not meta.is_function(self[name]) then
                rt.error("In bt.Status:realize: key `" .. name .. "` of config at `" .. self._path .. "` has wrong type: expected `function`, got `" .. meta.typeof(self[name]) .. "`")
            end
        else
            self[name] = nil
        end
    end

    self.sprite_id = config.sprite_id
    meta.assert_string(self.sprite_id)

    if config.sprite_index ~= nil then
        self.sprite_index = config.sprite_index
    end

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