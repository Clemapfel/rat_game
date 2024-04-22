rt.settings.battle.global_status = {
    config_path = "battle/configs/global_status"
}

--- @class GlobalStatus
--- @brief cached instancing, moves with the same ID will always return the same instance
bt.GlobalStatus = meta.new_type("GlobalStatus", function(id)
    local out = bt.GlobalStatus._atlas[id]
    if out == nil then
        local path = rt.settings.battle.global_status.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.GlobalStatus, {
            id = id,
            name = "UNINITIALIZED GLOBAL_STATUS @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        bt.GlobalStatus._atlas[id] = out
    end
    return out
end, {
    max_duration = POSITIVE_INFINITY,
    is_silent = false,

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_gained = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_lost = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_turn_start = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_turn_end = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_battle_start = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_battle_end = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_before_damage_taken = function(self, damage_taker, damage_dealer, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, damage_taker, damage_dealer, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return nil
    end,

    on_before_damage_dealt = function(self, damage_dealer, damage_taker, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, damage_dealer, damage_taker, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(gained_status)
        return nil
    end,

    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(lost_status)
        return nil
    end,

    -- (GlobalStatusInterface, GlobalStatusInterface, Table<Entity>) -> nil
    on_global_status_gained = function(self, gained_status, entities)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_global_status_interface(gained_status)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_global_status_lost = function(self, lost_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_global_status_interface(lost_status)
        return nil
    end,

    on_knocked_out = function(self, knocked_out_entity, knock_out_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(knocked_out_entity)
        meta.assert_is_status_interface(knock_out_causer)
        return nil
    end,

    on_helped_up = function(self, helped_up_entity, help_up_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(helped_up_entity)
        meta.assert_is_status_interface(help_up_causer)
        return nil
    end,

    on_killed = function(self, killed_entity, death_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(killed_entity)
        meta.assert_is_status_interface(death_causer)
        return nil
    end,

    on_switch = function(self, switched_entity, entity_at_old_position)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(switched_entity)
        meta.assert_is_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, stance_changer, old_stance, new_stance)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(stance_changer)
        meta.assert_is_stance_interface(old_stance)
        meta.assert_is_stance_interface(new_stance)
        return nil
    end,

    on_before_move = function(self, move_user, move, targets)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(move_user)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, move_user, move, targets)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(move_user)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return nil
    end,

    on_before_consumable = function(self, holder, consumable)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, holder, consumable)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return nil
    end,

    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.GlobalStatus._atlas = {}

--- @brief
function bt.GlobalStatus:realize()
    if self._is_realized == true then return end

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.GlobalStatus:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
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
        "max_duration"
    }

    for key in values(numbers) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_number(self[key])
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
function bt.GlobalStatus:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.GlobalStatus:get_id()
    return self.id
end

--- @brief
function bt.GlobalStatus:get_name()
    return self.name
end

--- @brief
function bt.GlobalStatus:get_max_duration()
    return self.max_duration
end