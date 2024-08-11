rt.settings.battle.entity = {
    config_path = "assets/configs/entities",
    name = "Character"
}

--- @class EntityState
bt.EntityState = meta.new_enum({
    ALIVE = "ALIVE",
    KNOCKED_OUT = "KNOCKED_OUT",
    DEAD = "DEAD"
})

--- @class AILevel
bt.AILevel = meta.new_enum({
    RANDOM = 0,
    LEVEL_1 = 1,
    LEVEL_2 = 2
})

--- @class bt.Entity
bt.Entity = meta.new_type("BattleEntity", function(id)
    meta.assert_string(id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Entity, {
        id = id,
        _path = path,
        _config_id = id,
        _is_realized = false,
    })

    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    is_enemy = true,

    hp_base = 100,
    attack_base = 0,
    defense_base = 0,
    speed_base = 0,

    n_move_slots = 25,
    n_equip_slots = 2,
    n_consumable_slots = 1,

    ai_level = bt.AILevel.RANDOM,

    -- non simulation
    sprite_id = "",
    sprite_index = 1,

    knocked_out_sprite_id = nil,
    knocked_out_sprite_index = nil,

    dead_sprite_id = nil,
    dead_sprite_index = nil,

    portrait_sprite_id = nil,
    portrait_sprite_index = nil,

    name = "",
    description = "(no description)",
})

--- @brief
function bt.Entity:realize()
    if self._is_realized == true then return end
    meta.set_is_mutable(self, true)

    local template = {
        name = rt.STRING,

        is_enemy = rt.BOOLEAN,
        hp_base = rt.UNSIGNED,
        attack_base = rt.UNSIGNED,
        defense_base = rt.UNSIGNED,
        speed_base = rt.UNSIGNED,

        ai_level = rt.UNSIGNED,
        sprite_id = rt.STRING,
        sprite_index = {rt.UNSIGNED, rt.STRING},

        knocked_out_sprite_id = rt.STRING,
        knocked_out_sprite_index = {rt.UNSIGNED, rt.STRING},

        dead_sprite_id = rt.STRING,
        dead_sprite_index = {rt.UNSIGNED, rt.STRING},

        portrait_sprite_id = rt.STRING,
        portrait_sprite_index = {rt.UNSIGNED, rt.STRING},

        n_move_slots = rt.INTEGER,
        n_equip_slots = rt.INTEGER,
        n_consumable_slots = rt.INTEGER,
    }

    rt.load_config(self._path, self, template)
    assert(self.n_move_slots < POSITIVE_INFINITY)
    assert(self.n_equip_slots < POSITIVE_INFINITY)
    assert(self.n_equip_slots < POSITIVE_INFINITY)

    STATE:add_entity(self)
    local multiplicity = STATE:entity_get_multiplicity(self)
    self.id = self.id .. self:_multiplicity_to_id_suffix(multiplicity)
    self.name = self.name .. self:_multiplicity_to_name_suffix(multiplicity)

    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Entity:_multiplicity_to_id_suffix(n)
    if n == 0 then
        return ""
    else
        local out = "_"
        if n < 10 then out = out .. "0" end
        return out .. tostring(n)
    end
end

--- @brief
function bt.Entity:_multiplicity_to_name_suffix(n)
    if n == 0 then
        return ""
    else
        return " " .. utf8.char(n + 0x03B1 - 1) -- lowercase greek letters
    end
end

--- @brief
function bt.Entity:get_id()
    return self.id
end

--- @brief
function bt.Entity:get_config_id()
    return self._config_id
end

--- @brief
function bt.Entity:get_name()
    return self.name
end

--- @brief
function bt.Entity:get_description()
    return self.description
end

--- @brief
function bt.Entity:get_is_enemy()
    return self.is_enemy
end

--- @brief
function bt.Entity:get_n_move_slots()
    return self.n_move_slots
end

--- @brief
function bt.Entity:get_n_equip_slots()
    return self.n_equip_slots
end

--- @brief
function bt.Entity:get_n_consumable_slots()
    return self.n_consumable_slots
end

--- @brief
function bt.Entity:get_ai_level()
    return self.ai_level
end

--- @brief
function bt.Entity:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.Entity:get_knocked_out_sprite_id()
    return self.knocked_out_sprite_id, self.knocked_out_sprite_index
end

--- @brief
function bt.Entity:get_dead_sprite_id()
    return self.dead_sprite_id, self.dead_sprite_index
end

--- @brief
function bt.Entity:get_portrait_sprite_id()
    return self.portrait_sprite_id, self.portrait_sprite_index
end

--- @brief
function bt.Entity:get_hp_current()
    return STATE:entity_get_hp(self)
end

for which in range("hp", "attack", "defense", "speed") do
    --- @brief get_hp_base_raw, get_attack_base_raw, get_defense_base_raw, get_speed_base_raw
    bt.Entity["get_" .. which .. "_base_raw"] = function(self)
        return self[which .. "_base"]
    end

    --- @brief get_hp_base, get_attack_base, get_defense_base, get_speed_base
    bt.Entity["get_" .. which .. "_base"] = function(self)
        local value = self["get_" .. which .. "_base_raw"](self)
        local equips = STATE:entity_list_equips(self)
        for equip in values(equips) do
            value = value + equip[which .. "_base_offset"]
        end

        for equip in values(equips) do
            value = value * equip[which .. "_base_factor"]
        end

        return math.ceil(value)
    end

    if which ~= "hp" then
        --- @brief get_attack_current, get_defense_current, get_speed_current
        bt.Entity["get_" .. which .. "_current"] = function(self)
            local value = self["get_" .. which .. "_base"](self)

            local statuses = STATE:entity_list_statuses(self)
            for status in values(statuses) do
                value = value + status[which .. "_offset"]
            end

            for status in values(statuses) do
                value = value * status[which .. "_factor"]
            end

            return math.ceil(value)
        end
    end

    --- @brief get_hp, get_attack, get_defense, get_speed
    bt.Entity["get_" .. which] = function(self)
        return self["get_" .. which .. "_current"]
    end
end
