rt.settings.battle.consumable = {
    config_path = "assets/battle/consumables"
}

--- @class
bt.Consumable = meta.new_type("Consumable", function(id)
    local path = rt.settings.battle.status.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Consumable, {
        id = id,
        name = "UNINITIALIZED CONSUMABLE @" .. path,
        _path = path,
        _is_realized = false
    })
    meta.set_is_mutable(out, false)
    return out
end, {
    hp_offset = 0,
    effect = function(consumer)
        meta.assert_isa(self, bt.Consumable)
        meta.assert_isa(self, bt.Entity)
    end
})

--- @brief
--function bt.Consumable: