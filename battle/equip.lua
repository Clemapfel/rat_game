rt.settings.battle.equip = {
    config_path = "assets/configs/equips",
    name = "Gear"
}

--- @class bt.Equip
bt.Equip = meta.new_type("Equip", function(id)
    local out = bt.Equip._atlas[id]
    if out == nil then
        local path = rt.settings.battle.equip.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.Equip, {
            id = id,
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

    hp_base_factor = 1,
    attack_base_factor = 1,
    defense_base_factor = 1,
    speed_base_factor = 1,

    is_silent = false,

    -- (EquipProxy, EntityProxy) -> nil
    effect = function(self, holder)
        meta.assert_equip_interface(self)
        meta.assert_entity_interface(holder)
    end,

    description = "(no description)",
    flavor_text = "",

    sprite_id = "",
    sprite_index = 1
})
bt.Equip._atlas = {}

--- @brief
function bt.Equip:realize()
    if self._is_realized == true then return end

    local template = {
        id = rt.STRING,
        name = rt.STRING,
        is_silent = rt.BOOLEAN,
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
    rt.load_config(self._path, self, template)
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
function bt.Equip:get_hp_base_factor()
    return self.hp_base_factor
end

--- @brief
function bt.Equip:get_attack_base_factor()
    return self.attack_base_factor
end

--- @brief
function bt.Equip:get_defense_base_factor()
    return self.defense_base_factor
end

--- @brief
function bt.Equip:get_speed_base_factor()
    return self.speed_base_factor
end

--- @brief
function bt.Equip:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.Equip:get_description()
    return self.description
end

--- @brief
function bt.Equip:get_flavor_text()
    return self.flavor_text
end

--- @brief
function bt.Equip:get_type()
    return self.type
end