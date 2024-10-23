rt.settings.battle.entity = {
    config_path = "assets/configs/entities",
    name = "Character",
}

--- @class EntityState
bt.EntityState = meta.new_enum("EntityState", {
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

--- @class bt.Entity
bt.Entity = meta.new_type("BattleEntity", function(state, id)
    meta.assert_isa(state, rt.GameState)
    meta.assert_string(id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Entity, {
        _path = path,
        _config_id = id,
        _state = state,
        _is_realized = false,
    })

    out.id = id
    out:realize()
    meta.set_is_mutable(out, false)
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
    sprite_id = "",
    sprite_index = 1,

    knocked_out_sprite_id = nil,
    knocked_out_sprite_index = nil,

    dead_sprite_id = nil,
    dead_sprite_index = nil,

    portrait_sprite_id = nil,
    portrait_sprite_index = nil,

    id = "",
    id_suffix = "",

    name = "",
    name_suffix = "",
    flavor_text = "(no flavor_text)",

    intrinsic_moves = {
        "STRUGGLE"
    }
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

        intrinsic_moves = rt.TABLE,

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

        flavor_text = rt.STRING
    }

    rt.load_config(self._path, self, template)
    self._state:add_entity(self)

    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Entity:update_id_from_multiplicity(n)
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
function bt.Entity:get_id()
    return self.id .. self.id_suffix
end

--- qbrief
function bt.Entity:get_id_suffix()
    return self.id_suffix
end

--- @brief
function bt.Entity:get_config_id()
    return self._config_id
end

--- @brief
function bt.Entity:get_name()
    return self.name .. self.name_suffix
end

--- @brief
function bt.Entity:get_flavor_text()
    return self.flavor_text
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
    return self._state:entity_get_hp(self)
end

for which in range("hp", "attack", "defense", "speed") do
    --- @brief get_hp_base_raw, get_attack_base_raw, get_defense_base_raw, get_speed_base_raw
    bt.Entity["get_" .. which .. "_base_raw"] = function(self)
        return self[which .. "_base"]
    end

    --- @brief get_hp_base, get_attack_base, get_defense_base, get_speed_base
    bt.Entity["get_" .. which .. "_base"] = function(self)
        local value = self["get_" .. which .. "_base_raw"](self)
        local equips = self._state:entity_list_equips(self)
        for equip in values(equips) do
            value = value + equip[which .. "_base_offset"]
        end

        for equip in values(equips) do
            value = value * equip[which .. "_base_factor"]
        end

        return math.max(0, math.ceil(value))
    end

    if which ~= "hp" then
        --- @brief get_attack_current, get_defense_current, get_speed_current
        bt.Entity["get_" .. which .. "_current"] = function(self)
            local value = self["get_" .. which .. "_base"](self)

            local statuses = self._state:entity_list_statuses(self)
            for status in values(statuses) do
                value = value + status[which .. "_offset"]
            end

            for status in values(statuses) do
                value = value * status[which .. "_factor"]
            end

            return math.max(0, math.ceil(value))
        end
    end

    --- @brief get_hp, get_attack, get_defense, get_speed
    bt.Entity["get_" .. which] = function(self)
        return self["get_" .. which .. "_current"](self)
    end
end

for which in range("move", "equip", "consumable") do
    --- @brief list_moves, list_equips, list_consumables
    bt.Entity["list_" .. which .. "s"] = function(self)
        return self._state["entity_list_" .. which .. "s"](self._state, self)
    end

    --- @brief list_move_slots, list_equip_slots, list_consumable_slots
    --- @return Unsigned, Table
    bt.Entity["list_" .. which .. "_slots"] = function(self)
        return self._state["entity_list_" .. which .. "_slots"](self._state, self)
    end
end

--- @brief
function bt.Entity:list_intrinsic_move_ids()
    local out = {}
    for id in values(self.intrinsic_moves) do
        table.insert(out, id)
    end
    return out
end

--- @brief
function bt.Entity:get_priority()
    return self._state:entity_get_priority(self)
end

--- @brief
function bt.Entity:get_is_stunned()
    return self._state:entity_get_is_stunned(self)
end