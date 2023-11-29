--- @class StatAlteration
rt.StatAlteration = meta.new_enum({
    MIN = -5,
    MINUS_4 = -4,
    MINUS_3 = -3,
    MINUS_2 = -2,
    MINUS_1 = -1,
    ZERO = 0,
    PLUS_1 = 1,
    PLUS_2 = 2,
    PLUS_3 = 3,
    PLUS_4 = 4,
    MAX = 5
})

--- @brief convert stat level to numerical factor
function rt._stat_alteration_to_factor(level)
    if level == rt.StatAlteration.MIN then
        return NEGATIVE_INFINITY
    elseif level == rt.StatAlteration.MINUS_4 then
        return 0.1
    elseif level == rt.StatAlteration.MINUS_3 then
        return 0.25
    elseif level == rt.StatAlteration.MINUS_2 then
        return 0.5
    elseif level == rt.StatAlteration.MINUS_1 then
        return 0.75
    elseif level == rt.StatAlteration.ZERO then
        return 1.0
    elseif level == rt.StatAlteration.PLUS_1 then
        return 1.25
    elseif level == rt.StatAlteration.PLUS_2 then
        return 1.5
    elseif level == rt.StatAlteration.PLUS_3 then
        return 1.75
    elseif level == rt.StatAlteration.PLUS_4 then
        return 2
    elseif level == rt.StatAlteration.MAX then
        return POSITIVE_INFINITY
    end
end

--- @brief raise state alteration by number of steps
function rt._stat_alteration_add(level, offset)
    _stat_alteration_add_offset_plus_1 = function(x)

        if x == rt.StatAlteration.MIN then
            return rt.StatAlteration.MIN
        end

        if x == rt.StatAlteration.MAX then
            return rt.StatAlteration.MAX
        end

        if level == rt.StatAlteration.MINUS_4 then
            return rt.StatAlteration.MINUS_3
        elseif level == rt.StatAlteration.MINUS_3 then
            return rt.StatAlteration.MINUS_2
        elseif level == rt.StatAlteration.MINUS_2 then
            return rt.StatAlteration.MINUS_1
        elseif level == rt.StatAlteration.MINUS_1 then
            return rt.StatAlteration.ZERO
        elseif level == rt.StatAlteration.ZERO then
            return rt.StatAlteration.PLUS_1
        elseif level == rt.StatAlteration.PLUS_1 then
            return rt.StatAlteration.PLUS_2
        elseif level == rt.StatAlteration.PLUS_2 then
            return rt.StatAlteration.PLUS_3
        elseif level == rt.StatAlteration.PLUS_3 then
            return rt.StatAlteration.PLUS_4
        elseif level == rt.StatAlteration.PLUS_4 then
            return rt.StatAlteration.PLUS_4
        end
    end

    _stat_alteration_add_offset_minus_1 = function(x)

        if x == rt.StatAlteration.MIN then
            return rt.StatAlteration.MIN
        end

        if x == rt.StatAlteration.MAX then
            return rt.StatAlteration.MAX
        end

        if level == rt.StatAlteration.MINUS_4 then
            return rt.StatAlteration.MINUS_4
        elseif level == rt.StatAlteration.MINUS_3 then
            return rt.StatAlteration.MINUS_4
        elseif level == rt.StatAlteration.MINUS_2 then
            return rt.StatAlteration.MINUS_3
        elseif level == rt.StatAlteration.MINUS_1 then
            return rt.StatAlteration.MINUS_2
        elseif level == rt.StatAlteration.ZERO then
            return rt.StatAlteration.MINUS_1
        elseif level == rt.StatAlteration.PLUS_1 then
            return rt.StatAlteration.ZERO
        elseif level == rt.StatAlteration.PLUS_2 then
            return rt.StatAlteration.PLUS_1
        elseif level == rt.StatAlteration.PLUS_3 then
            return rt.StatAlteration.PLUS_2
        elseif level == rt.StatAlteration.PLUS_4 then
            return rt.StatAlteration.PLUS_3
        end
    end

    local out = level
    if offset > 0 then
        while offset > 0 do
            out = _stat_alteration_add_offset_plus_1(out)
            offset = offset - 1
        end
    elseif offset < 0 then
        while offset < 0 do
            out = _stat_alteration_add_offset_minus_1(out)
            offset = offset + 1
        end
    end
    return out
end

rt.MC_ID = "MC"
rt.RAT_ID = "RAT"
rt.PROF_ID = "PROF"
rt.GIRLD_ID = "GIRL"
rt.WILDCARD_ID = "WILDCARD"

--- @class Entity
rt.Entity = meta.new_type("Entity", function(id)

    local entity = rt.ENTITIES[id]
    local out = meta.new(rt.Entity, {
        hp = entity.hp_base,
        hp_base = entity.hp_base,

        ap = entity.ap_base,
        ap_base = entity.ap_base,

        attack_base = entity.attack_base,
        attack_level = rt.StatAlteration.ZERO,

        defense_base = entity.defense_base,
        defense_level = rt.StatAlteration.ZERO,

        speed_base = entity.speed_base,
        speed_level = rt.StatAlteration.ZERO,

        --- @brief Move ID -> PP left
        moveset = {
            BASE_ATTACK = POSITIVE_INFINITY,
            BASE_PROTECT = POSITIVE_INFINITY
        },

        --- @brief Status ID -> table of status-specific fields
        status = {},

        is_enemy = true,
    })

    is_enemy = not (
        id == rt.MC_ID
        or id == rt.RAT_ID
        or id == rt.PROF_ID
        or id == rt.GIRL_ID
        or id == rt.WILDCARD_ID
    )

    for key, value in config.moveset do
        local move = rt.MOVES[key]
        out.movesset[key] = move.pp_base
    end
end)

--- @brief access hp after modifiers
function rt.Entity.get_hp(target) 
    meta.assert_isa(target, rt.Entity)
    return target.hp
end 

--- @brief access hp base
function rt.Entity.get_hp_base(target)
    meta.assert_isa(target, rt.Entity)
    return target.hp_base
end

--- @brief increase hp by value
function rt.Entity.add_hp(target, offset)
    set_hp(target:get_hp() + offset)
end

--- @brief reduce hp by value
function rt.Entity.reduce_hp(target, offset)
    set_hp(target:get_hp() - offset)
end

--- @brief modify hp
function rt.Entity.set_hp(target, new_value)
    meta.assert_isa(target, rt.Entity)

    new_value = clamp(new_value, 0, target.hp_base)
end

--- @brief access attack after modifiers
function rt.Entity.get_attack(target)
    meta.assert_isa(target, rt.Entity)
    local out = target.attack_base
    out = out * rt._stat_alteration_to_factor(target.attack_level)

    for id, _ in pairs(target.status) do
        out = out * rt.STATUS[id].attack_modifier.factor
    end
    for id, _ in pairs(target.status) do
        out = out + rt.STATUS[id].attack_modifier.offset
    end
    return out
end

function rt.Entity.raise_attack(target)
    rt.queue(function()

    end)
end
function rt.Entity.lower_attack(target, TODO) end
function rt.Entity.set_attack_level(target, TODO) end

--- @brief access defense after modifiers
function rt.Entity.get_defense(target)
    meta.assert_isa(target, rt.Entity)
    local out = target.defense_base
    out = out * rt._stat_alteration_to_factor(target.defense_level)

    for id, _ in pairs(target.status) do
        out = out * rt.STATUS[id].defense_modifier.factor
    end
    for id, _ in pairs(target.status) do
        out = out + rt.STATUS[id].defense_modifier.offset
    end
    return out
end

function rt.Entity.raise_defense(target, TODO) end
function rt.Entity.lower_defense(target, TODO) end
function rt.Entity.set_defense_level(target, TODO) end

--- @brief access speed after modifiers
function rt.Entity.get_speed(target)
    meta.assert_isa(target, rt.Entity)
    local out = target.speed_base
    out = out * rt._stat_alteration_to_factor(target.speed_level)

    for id, _ in pairs(target.status) do
        out = out * rt.STATUS[id].speed_modifier.factor
    end
    for id, _ in pairs(target.status) do
        out = out + rt.STATUS[id].speed_modifier.offset
    end
    return out
end

function rt.Entity.raise_speed(target, TODO) end
function rt.Entity.lower_speed(target, TODO) end
function rt.Entity.set_speed_level(target, TODO) end

function rt.Entity.get_is_enemy(target) end

function rt.Entity.is_ally_of(a, b)
    meta.assert_isa(a, rt.Entity)
    meta.assert_isa(b, rt.Entity)
    return a:get_is_enemy() == b:get_is_enemy()
end
