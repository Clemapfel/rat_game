rt.settings.battle.equippable = {
    config_path = "assets/battle/equippable"
}

--- @class bt.Equippable
bt.Equippable = meta.new_type("Equippable", function(id)
    local path = rt.settings.battle.equippable.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Consumable, {
        id = id,
        name = "UNINITIALIZED EQUIPPABLE @" .. path,
        _path = path,
        _is_realized = false
    })
    meta.set_is_mutable(out, false)
    return out
end, {
   hp_base_ofset = 0,
   attack_offset = 0,
   defense_offset = 0,
   speed_offset = 0,

   attack_factor = 1,
   defense_factor = 1,
   speed_factor = 1,

   effect = function(holder)
       meta.assert_isa(self, bt.Equippable)
       meta.assert_isa(holder, bt.Entity)
   end
})

--- @brief
function bt.Equippable:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Equippable:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    local numbers = {
        "hp_base_ofset",
        "attack_offset",
        "defense_offset",
        "speed_offset",

        "attack_factor",
        "defense_factor",
        "speed_factor",
    }

    for _, key in ipairs(numbers) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_number(self[key])
    end

    if config.effect ~= nil then
        self.effect = config.effect
    end
    meta.assert_function(self.effect)

    self._is_realized = true
    meta.set_is_mutable(self, false)
end