rt.settings.battle.consumable = {
    config_path = "assets/battle/consumables"
}

--- @class bt.Consumable
bt.Consumable = meta.new_type("Consumable", function(id)
    local out = bt.Consumable._atlas[id]
    if out == nil then
        local path = rt.settings.battle.consumable.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Consumable, {
            id = id,
            name = "UNINITIALIZED CONSUMABLE @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Consumable._atlas[id] = out
    end
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,

    on_turn_start = function(holder)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        return nil
    end,

    on_turn_end = function(holder)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        return nil
    end,

    on_battle_start = function(holder)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        return nil
    end,

    on_battle_end = function(holder)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        return nil
    end,

    on_damage_taken = function(holder, damage_dealer, damage)
        meta.asssert_isa(self, bt.Consumable)
        for entity in range(holder, damage_dealer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_damage_dealt = function(holder, damage_taker, damage)
        meta.asssert_isa(self, bt.Consumable)
        for entity in range(holder, damage_taker) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(holder, gained_status)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(gained_status, bt.Consumable)
        return true -- allow applying status
    end,

    on_status_lost = function(holder, lost_status)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(lost_status, bt.Consumable)
        return nil
    end,

    on_knocked_out = function(holder, knock_out_causer)
        meta.asssert_isa(self, bt.Consumable)
        for entity in range(holder, knock_out_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow knock out
    end,

    on_helped_up = function(holder, help_up_causer)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        return true -- allow help up
    end,

    on_death = function(holder, death_causer)
        meta.asssert_isa(self, bt.Consumable)
        for entity in range(holder, death_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow death
    end,

    on_switch = function(holder, entity_at_old_position)
        meta.asssert_isa(self, bt.Consumable)
        for entity in range(holder, entity_at_old_position) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        return true -- allow switch
    end,

    on_stance_change = function(holder, old_stance, new_stance)
        meta.assert_isa(self, bt.Consumable)
        for stance in range(old_stance, new_stance) do
            meta.assert_isa(stance, bt.Stance)
        end
        return true -- allow change
    end,

    on_before_move = function(holder, target, move_selection)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        return true -- allow move
    end,

    on_after_move = function(holder, target, move_selection)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        return nil
    end,

    on_before_consumable = function(holder, consumable)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(holder, consumable)
        meta.asssert_isa(self, bt.Consumable)
        meta.assert_isa(holder, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        return nil
    end,
    
    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.Consumable._atlas = {}

--- @brief
function bt.Consumable:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Consumable:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    local strings = {
        "name",
        "sprite_id",
        "description"
    }

    for key in values(strings) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_string(self[key])
    end

    local numbers = {
        "max_n_uses"
    }

    for key in values(numbers) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_number(self[key])
    end

    if config.sprite_index ~= nil then
        self.sprite_index = config.sprite_index
    end

    local functions = {
        "on_turn_start",
        "on_turn_end",
        "on_battle_start",
        "on_battle_end",
        "on_damage_taken",
        "on_damage_dealt",
        "on_status_gained",
        "on_status_lost",
        "on_knocked_out",
        "on_helped_up",
        "on_death",
        "on_switch",
        "on_stance_change",
        "on_before_move",
        "on_after_move",
        "on_before_consumable",
        "on_after_consumable"
    }

    for key in values(functions) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_function(self[key])
    end

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Consumable:get_id()
    return self.id
end

--- @brief
function bt.Consumable:get_name()
    return self.name
end

--- @brief
function bt.Consumable:get_max_n_uses()
    return self.max_n_uses
end

--- @brief
function bt.Consumable:get_sprite_id()
    return self.sprite_id, self.sprite_index
end
