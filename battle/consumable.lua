rt.settings.battle.consumable = {
    config_path = "battle/configs/consumables"
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

    on_turn_start = function(self, holder)
        return nil
    end,

    on_turn_end = function(self, holder)
        return nil
    end,

    on_battle_start = function(self, holder)
        return nil
    end,

    on_battle_end = function(self, holder)
        return nil
    end,

    on_damage_taken = function(self, holder, damage_dealer, damage)
        return damage -- new damage
    end,

    on_damage_dealt = function(self, holder, damage_taker, damage)
        return nil
    end,

    on_status_gained = function(self, holder, gained_status)
        return true -- allow applying status
    end,

    on_status_lost = function(self, holder, lost_status)
        return nil
    end,

    on_global_status_gained = function(self, holder, gained_global_status)
        return true -- allow applying global_status
    end,

    on_global_status_lost = function(self, holder, lost_global_status)
        return nil
    end,

    on_knocked_out = function(self, holder, knock_out_causer)
        return true -- allow knock out
    end,

    on_helped_up = function(self, holder, help_up_causer)
        return true -- allow help up
    end,

    on_killed = function(self, holder, death_cause)
        return true -- allow death
    end,

    on_switch = function(self, holder, entity_at_old_position)
        return true -- allow switch
    end,

    on_stance_change = function(self, holder, old_stance, new_stance)
        return true -- allow change
    end,

    on_before_move = function(self, holder, move, targets)
        return true -- allow move
    end,

    on_after_move = function(self, holder, move, targets)
        return nil
    end,

    on_before_consumable = function(self, holder, consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, holder, consumable)
        return nil
    end,
    
    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.Consumable._atlas = {}

--- @brief
function bt.Consumable:realize()
    if self._is_realized == true then return end
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
        "on_gained",
        "on_lost",
        "on_turn_start",
        "on_turn_end",
        "on_battle_start",
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
                rt.error("In bt.Consumable:realize: key `" .. name .. "` of config at `" .. self._path .. "` has wrong type: expected `function`, got `" .. meta.typeof(self[name]) .. "`")
            end
        end
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
