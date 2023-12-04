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
    })

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
bt.Entity.moveset = {}
bt.Entity.n_move_slots = POSITIVE_INFINITY

-- equipment
bt.Entity.n_equip_slots = 2
bt.Entity.equipment = {}            -- index -> ID

-- status
bt.Entity.status_ailments = rt.List()

-- stat level to factor
rt.settings.entity.level_to_factor = {}
rt.settings.entity.level_to_factor[-4] = 0.1
rt.settings.entity.level_to_factor[-3] = 0.25
rt.settings.entity.level_to_factor[-2] = 0.5
rt.settings.entity.level_to_factor[-1] = 0.75
rt.settings.entity.level_to_factor[ 0] = 1
rt.settings.entity.level_to_factor[ 1] = 1.25
rt.settings.entity.level_to_factor[ 2] = 1.5
rt.settings.entity.level_to_factor[ 3] = 1.75
rt.settings.entity.level_to_factor[ 4] = 2

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

    for _, status in pairs(self.status_ailments) do
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
