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
        get_hp = rt.Entity.get_hp,
        get_hp_base = rt.Entity.get_hp_base,
        set_hp = rt.Entity.set_hp,
        add_hp = rt.Entity.add_hp,
        reduce_hp = rt.Entity.reduce_hp,

        ap = entity.ap_base,
        ap_base = entity.ap_base,
        get_ap = rt.Entity.get_hp,
        get_ap_base = rt.Entity.get_hp_base,
        set_ap = rt.Entity.set_hp,
        add_ap = rt.Entity.add_hp,
        reduce_hp = rt.Entity.reduce_hp,

        attack = entity.attack_base,
        attack_base = entity.attack_base,
        attack_level = rt.StatAlteration.ZERO,
        get_attack = rt.Entity.get_attack,
        raise_attack_level = rt.Entity.raise_attack,
        lower_attack_level = rt.Entity.lower_attack,
        set_attack_level = rt.Entity.set_attack_level,

        defense = entity.defense_base,
        defense_base = entity.defense_base,
        defense_level = rt.StatAlteration.ZERO,
        get_defense = rt.Entity.get_attack,
        raise_defense = rt.Entity.raise_attack,
        lower_defense = rt.Entity.lower_attack,
        set_defense_level = rt.Entity.set_attack_level,

        speed = entity.speed_base,
        speed_base = entity.speed_base,
        speed_level = rt.StatAlteration.ZERO,
        get_speed = rt.Entity.get_attack,
        raise_speed = rt.Entity.raise_attack,
        lower_speed = rt.Entity.lower_attack,
        set_speed_level = rt.Entity.set_attack_level,

        moveset = {
            BASE_ATTACK,
            BASE_PROTECT
        },

        status = {},

        is_enemy = true,
        get_is_enemy = rt.Entity.get_is_enemy
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

function rt.Entity.get_hp(target, TODO) end
function rt.Entity.get_hp_base(target, TODO) end
function rt.Entity.set_hp(target, TODO) end
function rt.Entity.add_hp(target, TODO) end
function rt.Entity.reduce_hp(target, TODO) end

function rt.Entity.get_attack(target, TODO) end
function rt.Entity.raise_attack(target, TODO) end
function rt.Entity.lower_attack(target, TODO) end
function rt.Entity.set_attack_level(target, TODO) end

function rt.Entity.get_attack(target, TODO) end
function rt.Entity.raise_attack(target, TODO) end
function rt.Entity.lower_attack(target, TODO) end
function rt.Entity.set_attack_level(target, TODO) end

function rt.Entity.get_attack(target, TODO) end
function rt.Entity.raise_attack(target, TODO) end
function rt.Entity.lower_attack(target, TODO) end
function rt.Entity.set_attack_level(target, TODO) end

