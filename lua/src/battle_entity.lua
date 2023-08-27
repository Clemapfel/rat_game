

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

--- @class BattleEntity
rt.BattleEntity = meta.new_type("BattleEntity", function(id)

    local entity = rt.ENTITIES[id]
    local out = meta.new("BattleEntity", {
        hp = entity.hp_base,
        hp_base = entity.hp_base,

        ap = entity.ap_base,
        ap_base = entity.ap_base,

        attack = entity.attack_base,
        attack_base = entity.attack_base,
        attack_level = rt.StatAlteration.ZERO,

        defense = entity.defense_base,
        defense_base = entity.defense_base,
        defense_level = rt.StatAlteration.ZERO,

        speed = entity.speed_base,
        speed_base = entity.speed_base,
        speed_level = rt.StatAlteration.ZERO,

        moveset = {
            BASE_ATTACK,
            BASE_PROTECT
        }
    })

    for key, value in config.moveset do
        local move = rt.MOVES[key]
        out.movesset[key] = move.pp_base
    end
end)