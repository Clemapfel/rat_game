rt.settings.battle.entity = {
    config_path = "assets/configs/entities",
    name = "Character",
}

--- @class bt.EntityConfigState
bt.EntityState = meta.new_enum("EntityConfigState", {
    ALIVE = "ALIVE",
    KNOCKED_OUT = "KNOCKED_OUT",
    DEAD = "DEAD"
})

--- @class AILevel
bt.AILevel = meta.new_enum("AILevel", {
    RANDOM = 0,
    LEVEL_1 = 1,
    LEVEL_2 = 2
})

--- @enum bt.StatType
bt.StatType = meta.new_enum("StatType", {
    HP = "HP",
    ATTACK = "ATTACk",
    DEFENSE = "DEFENSE",
    SPEED = "SPEED",
    PRIORITY = "PRIORITY"
})

--- @class bt.EntityConfig
bt.EntityConfig = meta.new_type("EntityConfig", function(id)
    meta.assert_string(id)
    local out = bt.EntityConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.EntityConfig, {
            id = id,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.EntityConfig._atlas[id] = out
    end
    return out
end, {
    is_enemy = true,

    hp_base = 100,
    attack_base = 0,
    defense_base = 0,
    speed_base = 0,

    n_move_slots = 16,
    n_equip_slots = 0,
    n_consumable_slots = 1,

    ai_level = bt.AILevel.RANDOM,

    -- non simulation
    id = "",
    
    sprite_id = "",
    sprite_index = 1,

    portrait_sprite_id = nil,
    portrait_sprite_index = nil,

    description = rt.Translation.battle.entity_default_description,
    flavor_text = rt.Translation.battle.entity_default_flavor_text,

    intrinsic_moves = {
        "STRUGGLE"
    }
})
bt.EntityConfig._atlas = {}

--- @brief
function bt.EntityConfig:realize()
    if self._is_realized == true then return end
    meta.set_is_mutable(self, true)

    local template = {
        name = rt.STRING,

        is_enemy = rt.BOOLEAN,
        hp_base = rt.UNSIGNED,
        attack_base = rt.UNSIGNED,
        defense_base = rt.UNSIGNED,
        speed_base = rt.UNSIGNED,

        intrinsic_moves = rt.TABLE,

        ai_level = rt.UNSIGNED,
        sprite_id = rt.STRING,
        sprite_index = {rt.UNSIGNED, rt.STRING},
        knocked_out_sprite_index = {rt.UNSIGNED, rt.STRING},
        dead_sprite_index = {rt.UNSIGNED, rt.STRING},

        portrait_sprite_id = rt.STRING,
        portrait_sprite_index = {rt.UNSIGNED, rt.STRING},

        n_move_slots = rt.INTEGER,
        n_equip_slots = rt.INTEGER,
        n_consumable_slots = rt.INTEGER,

        description = rt.STRING,
        flavor_text = rt.STRING
    }

    rt.load_config(self._path, self, template)
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.EntityConfig:update_id_from_multiplicity(n)
    local id_suffix = ""
    local name_suffix = ""

    if n > 1 then
        name_suffix = " " .. utf8.char(n + 0x03B1 - 1) -- lowercase greek letters

        id_suffix = "_"
        if n < 10 then id_suffix = id_suffix .. "0" end
        id_suffix = id_suffix .. tostring(n)
    end

    meta.set_is_mutable(self, true)
    self.id_suffix = id_suffix
    self.name_suffix = name_suffix
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.EntityConfig:get_id()
    return self.id
end

--- @brief
function bt.EntityConfig:get_flavor_text()
    return self.flavor_text
end

--- @brief
function bt.EntityConfig:get_is_enemy()
    return self.is_enemy
end

--- @brief
function bt.EntityConfig:get_n_move_slots()
    return self.n_move_slots
end

--- @brief
function bt.EntityConfig:get_n_equip_slots()
    return self.n_equip_slots
end

--- @brief
function bt.EntityConfig:get_n_consumable_slots()
    return self.n_consumable_slots
end

--- @brief
function bt.EntityConfig:get_ai_level()
    return self.ai_level
end

--- @brief
function bt.EntityConfig:get_sprite_id()
    return self.sprite_id, self.sprite_index
end

--- @brief
function bt.EntityConfig:get_knocked_out_sprite_id()
    return self.knocked_out_sprite_id, self.knocked_out_sprite_index
end

--- @brief
function bt.EntityConfig:get_dead_sprite_id()
    return self.dead_sprite_id, self.dead_sprite_index
end

--- @brief
function bt.EntityConfig:get_portrait_sprite_id()
    return self.portrait_sprite_id, self.portrait_sprite_index
end

--- @brief
function bt.EntityConfig:list_intrinsic_move_ids()
    return {table.unpack(self.intrinsic_moves)}
end