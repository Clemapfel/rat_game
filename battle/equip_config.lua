rt.settings.battle.equip = {
    config_path = "assets/configs/equips",
    name = "Gear"
}

--- @class bt.EquipConfig
bt.EquipConfig = meta.new_type("EquipConfig", function(id)
    local out = bt.EquipConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.equip.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.EquipConfig, {
            id = id,
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

    hp_base_factor = 1,
    attack_base_factor = 1,
    defense_base_factor = 1,
    speed_base_factor = 1,

    -- (EquipProxy, EntityProxy) -> nil
    effect = nil,

    description = rt.Translation.battle.equip_default_description,
    flavor_text = rt.Translation.battle.equip_default_flavor_text,
    see_also = {},

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
        description = rt.STRING,
        flavor_text = rt.STRING,
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
    self.see_also = {}
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

--- @brief
function bt.EquipConfig:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.EquipConfig:get_description()
    return self.description
end

--- @brief
function bt.EquipConfig:get_flavor_text()
    return self.flavor_text
end