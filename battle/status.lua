rt.settings.battle.status = {
    config_path = "assets/battle/status"
}

--- @brief Status
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
    is_field_effect = false,

    on_gained = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_lost = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return nil
    end,

    on_turn_start = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return nil
    end,

    on_turn_end = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return nil
    end,

    on_battle_start = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return nil
    end,

    on_battle_end = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return nil
    end,

    on_damage_taken = function(afflicted, damage_dealer, damage)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, damage_dealer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_damage_dealt = function(afflicted, damage_taker, damage)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, damage_taker) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        return nil
    end,
    
    on_other_status_gained = function(afflicted, gained_status)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(gained_status, bt.Status)
        return true -- allow applying status
    end,

    on_other_status_lost = function(afflicted, lost_status)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(lost_status, bt.Status)
        return nil
    end,
    
    on_knocked_out = function(afflicted, knock_out_causer)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, knock_out_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow knock out
    end,

    on_helped_up = function(afflicted, help_up_causer)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        return true -- allow help up
    end,
    
    on_death = function(afflicted, death_causer)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, death_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow death
    end,

    on_switch = function(afflicted, entity_at_old_position)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, entity_at_old_position) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow switch
    end,

    on_stance_change = function(afflicted, old_stance, new_stance)
        meta.assert_isa(self, bt.Status)
        for stance in range(old_stance, new_stance) do
            meta.assert_isa(stance, bt.Stance)
        end
        return true -- allow change
    end,

    on_before_move = function(afflicted, target, move_selection)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        return true -- allow move
    end,

    on_after_move = function(afflicted, target, move_selection)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        return nil
    end,

    on_before_consumable = function(afflicted, consumable)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(afflicted, consumable)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        return nil
    end,

    is_silent = false,

    sprite_id = "",
    sprite_index = 1
})
bt.Status._atlas = {}

--- @brief
function bt.Status:realize()
    if self._is_realized then return end

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

    for _, key in ipairs(numbers) do
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

    local bools = {
        "is_field_effect",
    }

    for _, key in ipairs(bools) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_boolean(self[key])
    end

    local functions = {
        "on_gained",
        "on_lost",
        "on_turn_start",
        "on_turn_end",
        "on_battle_start",
        "on_battle_end",
        "on_damage_taken",
        "on_damage_dealt",
        "on_other_status_gained",
        "on_other_status_lost",
        "on_knocked_out",
        "on_helped_up",
        "on_death",
        "on_switch",
        "on_stance_change",
        "on_before_move",
        "on_after_move",
        "on_before_consumable",
        "on_after_consumable",
    }

    for _, key in ipairs(functions) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_function(self[key])
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