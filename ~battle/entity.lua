rt.settings.entity = {
    infinity_display_value = 9999
}

--- @class bt.BattleEntity
bt.BattleEntity = meta.new_type("Entity", rt.SignalEmitter, function(id)

    local path = "battle/configs/entities/" .. id .. ".lua"
    if meta.is_nil(love.filesystem.getInfo(path)) then
        rt.error("In Entity(\"" .. id .. "\"): path `" .. path .. "` does not exist")
    end
    local config_file, error_maybe = load(love.filesystem.read(path))
    if meta.is_nil(config_file) then
        rt.error("In Entity(\"" .. id .. "\"): error parsing file at `" .. path .. "`: " .. error_maybe)
    end

    local config = config_file()
    local out = meta.new(bt.BattleEntity, {
        id = id,

        -- cleartext name
        name = "",
        description = "(no description)",
        is_enemy = false,

        -- sprite IDs
        portrait = "default",
        battle_sprite = "default",

        -- HP stat
        hp_base = 1,
        hp_ev = 0,
        hp_current = 1,

        -- ATK stat
        attack_base = 0,
        attack_ev = 0,
        attack_level = 0,

        -- DEF stat
        defense_base = 0,
        defense_ev = 0,
        defense_level = 0,

        -- SPD stat
        speed_base = 0,
        speed_ev = 0,
        speed_level = 0,

        -- moves
        moveset = {},                -- bt.Action -> n_uses
        n_move_slots = POSITIVE_INFINITY,

        -- equipment
        n_equip_slots = 2,
        equipment = {},              -- slot_index -> rt.Equipment

        -- status
        status_ailments = {}        -- rt.StatusAilment -> Elapsed
    })

    out:signal_add("changed")

    local metatable = getmetatable(out)
    metatable.__newindex = function(self, name, value)
        rt.error("In bt.BattleEntity.__newindex: Entity properties cannot be modified directly, use one of its member functions instead.")
        meta.get_properties(self)[name] = value
    end

    local name = config.name
    meta.assert_string(name)
    out.name = name

    for which in range("hp", "attack", "defense", "speed") do
        local value = config[which .. "_base"]
        meta.assert_number(value)
        out[which .. "_base"] = value
    end

    for which in range("portrait", "battle_sprite", "description") do
        local value = config[which]
        if not meta.is_nil(value) then
            meta.assert_string(value)
            out[which] = value
        end
    end

    out.hp_current = out.hp_base
    return out
end)

--- @brief [internal]
rt.settings.entity._debug_id = 1
function bt._generate_debug_entity()
    local id = rt.settings.entity._debug_id
    local entity = meta.new(bt.BattleEntity, {
        id = "DEBUG_" .. ternary(id < 10, "0", "") .. tostring(id)
    })
    rt.settings.entity._debug_id = rt.settings.entity._debug_id + 1

    entity.name = "Debug Entity #" .. tostring(id)
    entity.hp_base = rt.random.integer(10, 150)
    entity.hp_ev = 0
    entity.hp_current = rt.random.integer(10, entity.hp_base)

    for which in range("attack", "defense", "speed") do
        entity[which .. "_base"] = rt.random.integer(1, 100)
        entity[which .. "_ev"] = 0
        entity[which .. "_level"] = rt.random.choose({0, 0, 0, 0, -1, 1})
    end

    entity.is_enemy = true
    return entity
end

-- stat level to factor
rt.settings.entity.level_to_factor = {}
rt.settings.entity.level_to_factor[-4] = 0
rt.settings.entity.level_to_factor[-3] = 0.25
rt.settings.entity.level_to_factor[-2] = 0.5
rt.settings.entity.level_to_factor[-1] = 0.75
rt.settings.entity.level_to_factor[ 0] = 1
rt.settings.entity.level_to_factor[ 1] = 1.25
rt.settings.entity.level_to_factor[ 2] = 1.5
rt.settings.entity.level_to_factor[ 3] = 1.75
rt.settings.entity.level_to_factor[ 4] = POSITIVE_INFINITY

--- @brief
function bt.stat_level_to_factor(x)
    return rt.settings.entity.level_to_factor[x]
end

-- 1 ev to absolute offset
rt.settings.entity.ev_to_offset = 10

--- @brief calculate base
function bt.BattleEntity:_calculate_base(which)
    local base = self[which .. "_base"]
    local ev = self[which .. "_ev"] * rt.settings.entity.ev_to_offset
    return math.ceil(base + ev)
end

--- @brief calculate stat
function bt.BattleEntity:_calculate_stat(which)
    if which == "hp" then
        return self.hp_current
    end

    local base = self:_calculate_base(which)
    local level = self[which .. "_level"]
    
    if level < -4 or level > 4 then
        rt.error("In bt.BattleEntity._calculate_state: " .. which .. "_level `" .. tostring(level) .. "` is out of bounds")
    end

    for _, equipment in pairs(self.equipment) do
        base = base + equipment[which .. "_modifier"]
    end

    local out = base * rt.settings.entity.level_to_factor[level]
    if level >= 4 then out = rt.settings.entity.infinity_display_value end

    for status, _ in pairs(self.status_ailments) do
        out = out * status[which .. "_factor"]
    end

    return math.ceil(out)
end

function bt.BattleEntity:get_hp() return self:_calculate_stat("hp") end
function bt.BattleEntity:get_attack() return self:_calculate_stat("attack") end
function bt.BattleEntity:get_defense() return self:_calculate_stat("defense") end
function bt.BattleEntity:get_speed() return self:_calculate_stat("speed") end

function bt.BattleEntity:get_attack_level() return self.attack_level end
function bt.BattleEntity:get_defense_level() return self.defense_level end
function bt.BattleEntity:get_speed_level() return self.speed_level end

function bt.BattleEntity:get_hp_base() return self.hp_base end
function bt.BattleEntity:get_attack_base() return self.attack_base end
function bt.BattleEntity:get_defense_base() return self.defense_base end
function bt.BattleEntity:get_speed_base() return self.speed_base end

--- @brief [internal]
function bt.BattleEntity:_emit_changed()
    self:signal_emit("changed")
end

--- @brief add new status
function bt.BattleEntity:add_status_ailment(status_ailment)
    self.status_ailments[status_ailment] = 0
    self:_emit_changed()
end

--- @brief
function bt.BattleEntity:_get_status_ailment_elapsed(status)
    meta.assert_isa(status, bt.StatusAilment)
    local out = self.status_ailments[status]
    if meta.is_nil(out) then
        rt.error("In bt.BattleEntity:_get_status_ailmend_elapsed: entity is not afflicated by status `" .. status.id .. "`")
    end
    return out
end

--- @brief
function bt.BattleEntity:get_status_ailments()
    local out = {}
    for status, _ in pairs(self.status_ailments) do
        table.insert(out, status)
    end
    return out
end

--- @brief add move to moveset
function bt.BattleEntity:add_action(action)
    entity.moveset[action] = action.max_n_use
    self:_emit_changed()
end

--- @brief modify hp
function bt.BattleEntity:set_hp(value)
    self._hp_current = clamp(value, 0, self._hp_base)
    self:_emit_changed()
end

--- @brief
function bt.BattleEntity:add_hp(offset)
    self:set_hp(self:get_hp() + offset)
end

--- @brief
function bt.BattleEntity:reduce_hp(offset)
    self:set_hp(self:get_hp() - offset)
end

--- @brief modify stat level
for which in range("attack", "defense", "speed") do
    bt.BattleEntity["set_" .. which .. "_level"] = function(self, new_level)
        self[which .. "_level"] = new_level
        self:_emit_changed()
    end

    bt.BattleEntity["raise_" .. which .. "_level"] = function(self, new_level)
        self[ which .. "_level"] = clamp(new_level + 1, -3, 3)
        self:_emit_changed()
    end

    bt.BattleEntity["lower_" .. which .. "_level"] = function(self, new_level)
        self[ which .. "_level"] = clamp(new_level - 1, -3, 3)
        self:_emit_changed()
    end
end
