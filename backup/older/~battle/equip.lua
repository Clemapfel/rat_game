rt.settings.battle.equip = {
    config_path = "battle/configs/equips"
}

--- @class bt.EquipConfig
bt.EquipConfig = meta.new_type("Equip", function(id)
    local out = bt.EquipConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.equip.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.EquipConfig, {
            id = id,
            name = "UNINITIALIZED EQUIP @" .. path,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.EquipConfig._atlas[id] = out
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

    is_silent = true,

    -- (EquipInterface, EntityInterface) -> nil
    effect = function(self, holder)
        meta.assert_equip_interface(self)
        meta.assert_entity_interface(holder)
    end,

    description = "",
    sprite_id = "",
    sprite_index = 1
})
bt.EquipConfig._atlas = {}

--- @brief
function bt.EquipConfig:realize()
    if self._is_realized == true then return end

    local template = {
        id = rt.STRING,
        name = rt.STRING,
        is_silent = rt.BOOLEAN,
        description = rt.STRING,
        sprite_id = rt.STRING,
        sprite_index = { rt.UNSIGNED, rt.STRING },

        hp_base_offset = rt.SIGNED,
        attack_base_offset = rt.SIGNED,
        defense_base_offset = rt.SIGNED,
        speed_base_offset = rt.SIGNED,

        hp_base_factor = rt.FLOAT,
        attack_base_factor = rt.FLOAT,
        defense_base_factor = rt.FLOAT,
        speed_base_factor = rt.FLOAT,

        effect = rt.FUNCTION
    }

    meta.set_is_mutable(self, true)
    rt.load_config(self._path, self, template)
    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.EquipConfig:get_id()
    return self.id
end

--- @brief
function bt.EquipConfig:get_name()
    return self.name
end

--- @brief
function bt.EquipConfig:get_hp_base_offset()
    return self.hp_base_offset
end

--- @brief
function bt.EquipConfig:get_attack_base_offset()
    return self.attack_base_offset
end

--- @brief
function bt.EquipConfig:get_defense_base_offset()
    return self.defense_base_offset
end

--- @brief
function bt.EquipConfig:get_speed_base_offset()
    return self.speed_base_offset
end

--- @brief
function bt.EquipConfig:get_hp_base_factor()
    return self.hp_base_factor
end

--- @brief
function bt.EquipConfig:get_attack_base_factor()
    return self.attack_base_factor
end

--- @brief
function bt.EquipConfig:get_defense_base_factor()
    return self.defense_base_factor
end

--- @brief
function bt.EquipConfig:get_speed_base_factor()
    return self.speed_base_factor
end


