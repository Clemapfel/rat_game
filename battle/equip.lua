rt.settings.battle.equip = {
    config_path = "assets/battle/equips"
}

--- @class bt.Equip
bt.Equip = meta.new_type("Equip", function(id)
    local out = bt.Equip._atlas[id]
    if out == nil then
        local path = rt.settings.battle.equip.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Equip, {
            id = id,
            name = "UNINITIALIZED EQUIP @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.Equip._atlas[id] = out
    end
    return out
end, {
   hp_base_offset = 0,
   attack_base_offset = 0,
   defense_base_offset = 0,
   speed_base_offset = 0,

   attack_factor = 1,
   defense_factor = 1,
   speed_factor = 1,

   effect = function(self, holder)
       meta.assert_is_equip_interface(self)
       meta.assert_is_entity_interface(holder)
   end,

   description = "",
   sprite_id = "",
   sprite_index = 1
})
bt.Equip._atlas = {}

--- @brief
function bt.Equip:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Equip:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    local numbers = {
        "hp_base_offset",
        "attack_base_offset",
        "defense_base_offset",
        "speed_base_offset",

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

--- @brief
function bt.Equip:get_id()
    return self.id
end

--- @brief
function bt.Equip:get_name()
    return self.name
end

--- @brief
function bt.Equip:get_hp_base_offset()
    return self.hp_base_offset
end

--- @brief
function bt.Equip:get_attack_base_offset()
    return self.attack_base_offset
end

--- @brief
function bt.Equip:get_defense_base_offset()
    return self.defense_base_offset
end

--- @brief
function bt.Equip:get_speed_base_offset()
    return self.speed_base_offset
end

--- @brief
function bt.Equip:get_attack_factor()
    return self.attack_factor
end

--- @brief
function bt.Equip:get_defense_factor()
    return self.defense_factor
end

--- @brief
function bt.Equip.get_speed_factor()
    return self.speed_factor
end


