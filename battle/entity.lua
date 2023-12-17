rt.settings.entity = {
    infinity_display_value = 9999
}

--- @class bt.Entity
bt.Entity = meta.new_type("Entity", function(id)

    local path = "battle/configs/entities/" .. id .. ".lua"
    if meta.is_nil(love.filesystem.getInfo(path)) then
        rt.error("In Entity(\"" .. id .. "\"): path `" .. path .. "` does not exist")
    end
    local config_file, error_maybe = load(love.filesystem.read(path))
    if meta.is_nil(config_file) then
        rt.error("In Entity(\"" .. id .. "\"): error parsing file at `" .. path .. "`: " .. error_maybe)
    end

    local config = config_file()
    local out = meta.new(bt.Entity, {
        id = id
    }, rt.SignalEmitter)

    out:signal_add("changed")

    local name = config.name
    meta.assert_string(name)
    out.name = name

    for _, which in pairs({"hp", "attack", "defense", "speed"}) do
        local value = config[which .. "_base"]
        meta.assert_number(value)
        out[which .. "_base"] = value
    end

    for _, which in pairs({"portrait", "battle_sprite", "description"}) do
        local value = config[which]
        if not meta.is_nil(value) then
            meta.assert_string(value)
            out[which] = value
        end
    end

    out.hp_current = out.hp_base
    return out
end)

-- cleartext name
bt.Entity.name = ""
bt.Entity.description = "(no description)"

-- sprite IDs
bt.Entity.portrait = "default"
bt.Entity.battle_sprite = "default"

-- HP stat
bt.Entity.hp_base = 1
bt.Entity.hp_ev = 0
bt.Entity.hp_current = 1

-- ATK stat
bt.Entity.attack_base = 0
bt.Entity.attack_ev = 0
bt.Entity.attack_level = 0

-- DEF stat
bt.Entity.defense_base = 0
bt.Entity.defense_ev = 0
bt.Entity.defense_level = 0

-- SPD stat
bt.Entity.speed_base = 0
bt.Entity.speed_ev = 0
bt.Entity.speed_level = 0

-- moves
bt.Entity.moveset = {}                -- bt.Action -> n_uses
bt.Entity.n_move_slots = POSITIVE_INFINITY

-- equipment
bt.Entity.n_equip_slots = 2
bt.Entity.equipment = {}              -- slot_index -> rt.Equipment

-- status
bt.Entity.status_ailments = {}        -- rt.StatusAilment -> Elapsed

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
rt.settings.entity.ev_to_offset = 100

--- @brief calculate base
function bt.Entity:_calculate_base(which)
    local base = self[which .. "_base"]
    local ev = self[which .. "_ev"] * rt.settings.entity.ev_to_offset
    return math.ceil(base + ev)
end

--- @brief calculate stat
function bt.Entity:_calculate_stat(which)
    if which == "hp" then
        return self.hp_current
    end

    local base = self:_calculate_base(which)
    local level = self[which .. "_level"]
    
    if level < -4 or level > 4 then
        rt.error("In bt.Entity._calculate_state: " .. which .. "_level `" .. tostring(level) .. "` is out of bounds")
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

function bt.Entity:get_hp() return self:_calculate_stat("hp") end
function bt.Entity:get_attack() return self:_calculate_stat("attack") end
function bt.Entity:get_defense() return self:_calculate_stat("defense") end
function bt.Entity:get_speed() return self:_calculate_stat("speed") end

function bt.Entity:get_attack_level() return self.attack_level end
function bt.Entity:get_defense_level() return self.defense_level end
function bt.Entity:get_speed_level() return self.speed_level end

function bt.Entity:get_hp_base() return self.hp_base end
function bt.Entity:get_attack_base() return self.attack_base end
function bt.Entity:get_defense_base() return self.defense_base end
function bt.Entity:get_speed_base() return self.speed_base end

--- @brief [internal]
function bt.Entity:_emit_changed()
    self:signal_emit("changed")
end

--- @brief add new status
function bt.Entity:add_status_ailment(status_ailment)
    self.status_ailments[status_ailment] = 0
    self:_emit_changed()
end

--- @brief
function bt.Entity:_get_status_ailment_elapsed(status)
    meta.assert_isa(status, bt.StatusAilment)
    local out = self.status_ailments[status]
    if meta.is_nil(out) then
        rt.error("In bt.Entity:_get_status_ailmend_elapsed: entity is not afflicated by status `" .. status.id .. "`")
    end
    return out
end

--- @brief
function bt.Entity:get_status_ailments()
    local out = {}
    for status, _ in pairs(self.status_ailments) do
        table.insert(out, status)
    end
    return out
end

--- @brief add move to moveset
function bt.Entity:add_action(action)
    entity.moveset[action] = action.max_n_use
    self:_emit_changed()
end

--- @brief modify hp
function bt.Entity:set_hp(value)
    self._hp_current = clamp(value, 0, self._hp_base)
    self:_emit_changed()
end

--- @brief
function bt.Entity:add_hp(offset)
    self:set_hp(self:get_hp() + offset)
end

--- @brief
function bt.Entity:reduce_hp(offset)
    self:set_hp(self:get_hp() - offset)
end

--- @brief modify stat level
for _, which in ipairs({"attack", "defense", "speed"}) do
    bt.Entity["set_" .. which .. "_level"] = function(self, new_level)
        self[which .. "_level"] = new_level
        self:_emit_changed()
    end

    bt.Entity["raise_" .. which .. "_level"] = function(self, new_level)
        self[ which .. "_level"] = clamp(new_level + 1, -3, 3)
        self:_emit_changed()
    end

    bt.Entity["lower_" .. which .. "_level"] = function(self, new_level)
        self[ which .. "_level"] = clamp(new_level - 1, -3, 3)
        self:_emit_changed()
    end
end
