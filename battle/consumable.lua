rt.settings.battle.consumable = {
    config_path = "assets/battle/consumables"
}

--- @class bt.Consumable
bt.Consumable = meta.new_type("Consumable", function(id)
    local path = rt.settings.battle.consumable.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Consumable, {
        id = id,
        name = "UNINITIALIZED CONSUMABLE @" .. path,
        _path = path,
        _is_realized = false
    })
    meta.set_is_mutable(out, false)
    return out
end, {
    effect = function(consumer)
        meta.assert_isa(self, bt.Consumable)
        meta.assert_isa(consumer, bt.BattleEntity)
    end
})

--- @brief
function bt.Consumable:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Consumable:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    -- load properties if specified, assert correct type, use default if left unspecified
    local config = chunk()
    meta.set_is_mutable(self, true)

    self.effect = config.effct
    meta.assert_number(self.effect)

    self._is_realized = true
    meta.set_is_mutable(self, false)
end