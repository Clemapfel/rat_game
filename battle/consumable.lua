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
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    on_turn_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    on_battle_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, Unsigned) -> nil
    on_hp_gained = function(self, holder, value)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_number(value)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(gained_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, StatusInterface)
    on_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(lost_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(gained_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(lost_status)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_knocked_out = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_helped_up = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface) -> nil
    on_killed = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, EntityInterface) -> nil
    on_switch = function(self, holder, entity_at_old_position)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, holder, old_stance, new_stance)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_stance_interface(old_stance)
        meta.assert_stance_interface(new_stance)
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, MoveInterface, Table<EntityInterface>)
    on_move = function(self, holding_user, move, targets)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holding_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
        return nil
    end,

    -- (ConsumableInterface, EntityInterface, ConsumableInterface)
    on_consumable_consumed = function(self, holder, other_consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(other_consumable)
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
        "on_battle_end",
        "on_hp_gained",
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
        "on_consumable_consumed"
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
