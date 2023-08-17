--- @class Status
rt.Status = meta.new_enum({
    DEAD = "DEAD",
    KNOCKED_OUT = "KNOCKED_OUT",
    ALIVE = "ALIVE",
})

--- @brief set status to knocked out
--- @param entity Entity
function rt.knock_out(entity)

    meta.assert_type(rt.Entity, entity, "knock_out")

    -- @todo log

    entity.status = rt.Status.KNOCKED_OUT

    entity.hp_current = 0
    entity.ap_current = 0

    entity.attack_level = rt.StatLevel.ZERO
    entity.defense_level = rt.StatLevel.ZERO
    entity.speed_level = rt.StatLevel.ZERO
    entity.effects = Set()
end

--- @brief kill
--- @param entity Entity
function rt.kill(entity)

    meta.assert_type(rt.Entity, entity, "kill")

    -- @todo log

    entity.status = rt.Status.DEAD

    entity.hp_current = 0
    entity.ap_current = 0

    entity.status = rt.Status.KNOCKED_OUT
    entity.attack_level = rt.StatLevel.ZERO
    entity.defense_level = rt.StatLevel.ZERO
    entity.speed_level = rt.StatLevel.ZERO
    entity.effects = Set()
end