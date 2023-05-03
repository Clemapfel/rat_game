--- @class Entity
rt.Entity = meta.new_type("Entity", {

    id = "",
    name = "",
    gender = rt.GrammaticGender.NEUTRAL,
    is_enemy = true,

    attack_base = meta.Number(1),
    defense_base = meta.Number(1),
    speed_base = meta.Number(1),

    hp_base = meta.Number(1),
    hp_current = meta.Number(0),

    ap_base = meta.Number(1),
    ap_current = meta.Number(0),

    attack_level = rt.StatLevel.ZERO,
    defense_level = rt.StatLevel.ZERO,
    speed_level = rt.StatLevel.ZERO,

    status = rt.ALIVE,

    effects = Set() -- rt.ContinuousEffect
})

meta.set_constructor(rt.Entity, function(this, id)

    if not meta.is_valid_name(id) then
        error("[ERROR] In Entity(): Argument `id` is not a valid identifier")
    end

    local out = meta.new(rt.Entity)
    out.id = id
    out.name = id
    out.hp_current = out.hp_base
    out.ap_current = out.ap_base
    return out
end)

--- @brief get current stat value
--- @param entity Entity
--- @return Number
function rt.generate.get_stat(stat)
    return function(entity)
        meta.assert_type(rt.Entity, entity, "get_" .. stat)

        local out = entity[stat .. "_base"]

        if rt.current_weather ~= nil then
            out = out * rt.continuous_effect[stat .. "_factor"]
        end

        for effect in pairs(entity.effects) do
            out = out * effect[stat .. "_factor"]
        end

        local level = entity[stat .. "_level"]
        if level ~= nil then
            out = out * rt.stat_level_to_factor(level)
        end

        if rt.current_weather ~= nil then
            out = out * rt.continuous_effect[stat .. "_offset"]
        end

        for effect in pairs(entity.effects) do
            out = out + effect[stat .. "_offset"]
        end

        return out
    end
end

--- @brief get current stat value
--- @param entity Entity
--- @return Number
function rt.generate.set_stat(stat)
    return function(entity, value)

        meta.assert_type(rt.Entity, entity, "set_" .. stat, 1)
        meta.assert_number(value, "set_" .. stat, 2)

        local delta = value - entity[stat .. "_current"]
        entity[stat .. "_current"] = value

        if delta > 0 then
            rt.log(entity.name .. " gained " .. serialize(delta) .. " " .. stat)
        elseif delta < 0 then
            rt.log(entity.name .. " lost " .. serialize(math.abs(delta)) .. " " .. stat)
        else
            rt.log(entity.name .. "s " .. stat .. " remained unchanged")
        end
    end
end

--- @brief get stat base
--- @param entity Entity
--- @return Number
function rt.generate.get_stat_base(stat)
    return function(entity)
        meta.assert_type(rt.Entity, entity, "get_" .. stat .. "_base", 1)
        return entity[stat .. "_base"]
    end
end

--- @brief get stat level
--- @param entity Entity
--- @return StatLevel
function rt.generate.get_stat_level(stat)
    return function(entity)
        meta.assert_type(rt.Entity, entity, "get_" .. stat .. "_level", 1)
        return entity[stat .. "_level"]
    end
end

--- @brief get stat level
--- @param entity Entity
--- @param StatLevel
function rt.generate.set_stat_level(stat)
    return function(entity, level)
        meta.assert_type(rt.Entity, entity, "set_" .. stat .. "_level", 1)
        meta.assert_enum(rt.StatLevel, level, "set_" .. stat .. "_level", 2)

        entity[stat .. "_level"] = level
        --@todo log
    end
end

--- @brief raise stat level by 1
--- @param entity Entity
function rt.generate.raise_stat_level(stat)
    return function(entity)
        meta.assert_type(rt.Entity, entity, "raise" .. stat .. "_level", 1)

        local current = rt["get_" .. stat .. "_level"](entity)
        local next = rt.StatLevel.ZERO

        if current == rt.StatLevel.MAX then
            -- @todo log
            return
        end

        next = current + 1
        rt["set_" .. stat .. "_level"](entity, next)
    end
end

--- @brief raise stat level by 1
--- @param entity Entity
function rt.generate.lower_stat_level(stat)
    return function(entity)
        meta.assert_type(rt.Entity, entity, "lower_" .. stat .. "_level", 1)

        local current = rt["get_" .. stat .. "_level"](entity)
        local next = rt.StatLevel.ZERO

        if current == rt.StatLevel.MIN then
            -- @todo log
            return
        end

        next = current - 1
        rt["set_" .. stat .. "_level"](entity, next)
    end
end

--- @brief add to stat
--- @param entity Entity
--- @param value Number
function rt.generate.add_stat(stat)
    return function(entity, value)
        meta.assert_type(rt.Entity, entity, "add_" .. stat, 1)
        meta.assert_number(value, "add_" .. stat, 2)

        rt["set_" .. stat](entity, rt["get_" .. stat](entity) + value)
    end
end

--- @brief subtract from stat
--- @param entity Entity
--- @param value Number
function rt.generate.reduce_stat(stat)
    return function(entity, value)
        meta.assert_type(rt.Entity, entity, "reduce_" .. stat, 1)
        meta.assert_number(value, "reduce_" .. stat, 2)

        rt["set_" .. stat](entity, rt["get_" .. stat](entity) - value)
    end
end

--- @brief set hp
--- @param entity Entity
--- @return Number
function rt.set_hp(entity, value)

    meta.assert_type(rt.Entity, entity, "set_hp", 1)
    meta.assert_number(value, "set_hp", 2)

    local delta = value - entity["hp_current"]

    if entity.status == rt.Status.KNOCKED_OUT and delta > 0 then
        rt.kill(entity)
        return
    end

    entity.hp_current = value

    if delta > 0 then
        rt.log(entity.name .. "s hp were restored by " .. serialize(delta))
    elseif delta < 0 then
        rt.log(entity.name .. " took " .. serialize(math.abs(delta)) .. " damage")
    else
        rt.log(entity.name .. "s " .. stat .. " remained unchanged")
    end

    if value == 0 then
        rt.knock_out(entity)
        return
    end
end

-- hp
rt.get_hp = rt.generate.get_stat("hp")
rt.get_hp_hp = rt.generate.get_stat_base("hp")
rt.add_hp = rt.generate.add_stat("hp")
rt.reduce_hp = rt.generate.reduce_stat("hp")

-- ap
rt.get_ap = rt.generate.get_stat("ap")
rt.get_ap_ap = rt.generate.get_stat_base("ap")
rt.set_ap = rt.generate.set_stat("ap")
rt.add_ap = rt.generate.add_stat("ap")
rt.reduce_ap = rt.generate.reduce_stat("ap")

-- attack
rt.get_attack = rt.generate.get_stat("attack")
rt.get_attack_base = rt.generate.get_stat_base("attack")
rt.get_attack_level = rt.generate.get_stat_level("attack")
rt.set_attack_level = rt.generate.set_stat_level("attack")
rt.raise_attack_level = rt.generate.raise_stat_level("attack")
rt.lower_attack_level = rt.generate.lower_stat_level("attack")

-- defense
rt.get_defense = rt.generate.get_stat("defense")
rt.get_defense_base = rt.generate.get_stat_base("defense")
rt.get_defense_level = rt.generate.get_stat_level("defense")
rt.set_defense_level = rt.generate.set_stat_level("defense")
rt.raise_defense_level = rt.generate.raise_stat_level("defense")
rt.lower_defense_level = rt.generate.lower_stat_level("defense")

-- speed
rt.get_speed = rt.generate.get_stat("speed")
rt.get_speed_base = rt.generate.get_stat_base("speed")
rt.get_speed_level = rt.generate.get_stat_level("speed")
rt.set_speed_level = rt.generate.set_stat_level("speed")
rt.raise_speed_level = rt.generate.raise_stat_level("speed")
rt.lower_speed_level = rt.generate.lower_stat_level("speed")

--- @brief get id
--- @param entity Entity
--- @return String
function rt.get_id(entity)
    meta.assert_type(rt.Entity, entity, "get_id")
    return entity.id
end

--- @brief get name
--- @param entity Entity
--- @return String
function rt.get_name(entity)
    meta.assert_type(rt.Entity, entity, "get_name")
    return entity.name
end