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
    local out = meta.new("Entity", {
        hp = entity.hp_base,
        hp_base = entity.hp_base,
        get_hp = rt.get_hp,
        get_hp_base = rt.get_hp_base,
        set_hp = rt.set_hp,
        add_hp = rt.add_hp,
        reduce_hp = rt.reduce_hp,

        ap = entity.ap_base,
        ap_base = entity.ap_base,
        get_ap = rt.get_hp,
        get_ap_base = rt.get_hp_base,
        set_ap = rt.set_hp,
        add_ap = rt.add_hp,
        reduce_hp = rt.reduce_hp,

        attack = entity.attack_base,
        attack_base = entity.attack_base,
        attack_level = rt.StatAlteration.ZERO,
        get_attack = rt.get_attack,
        raise_attack_level = rt.raise_attack,
        lower_attack_level = rt.lower_attack,
        set_attack_level = rt.set_attack_level,

        defense = entity.defense_base,
        defense_base = entity.defense_base,
        defense_level = rt.StatAlteration.ZERO,
        get_defense = rt.get_attack,
        raise_defense = rt.raise_attack,
        lower_defense = rt.lower_attack,
        set_defense_level = rt.set_attack_level,

        speed = entity.speed_base,
        speed_base = entity.speed_base,
        speed_level = rt.StatAlteration.ZERO,
        get_speed = rt.get_attack,
        raise_speed = rt.raise_attack,
        lower_speed = rt.lower_attack,
        set_speed_level = rt.set_attack_level,

        moveset = {
            BASE_ATTACK,
            BASE_PROTECT
        },

        status = {},

        is_enemy = true,
        get_is_enemy = rt.get_is_enemy
    })

    is_enemy = not (
        id == rt.MC_ID
        or id == rt.RAT_ID
        or id == PROF_ID
        or id == GIRL_ID
        or id == WILDCARD_ID
    )

    for key, value in config.moveset do
        local move = rt.MOVES[key]
        out.movesset[key] = move.pp_base
    end
end)

