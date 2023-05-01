--- @class Entity
rt.Entity = meta.new_type("Entity", {

    id = "",
    name = "",
    gender = rt.GrammaticGender.NEUTRAL,

    attack_base = meta.Number(0),
    defense_base = meta.Number(0),
    speed_base = meta.Number(0),

    hp_base = meta.Number(1),
    hp_current = meta.Number(0),

    ap_base = meta.Number(1),
    ap_current = meta.Number(0),

    attack_level = rt.StatLevel.ZERO,
    defense_level = rt.StatLevel.ZERO,
    speed_level = rt.StatLevel.ZERO,

    continuous_effects = Set()
})

meta.set_constructor(rt.Entity, function(this, id)

    if not meta.is_valid_name(id) then
        error("[ERROR] In Entity(): Argument `id` is not a valid identifier")
    end

    local out = meta.new(rt.Entity)
    out.id = id
    out.name = id
    return out
end)

--- @brief does entity have status
--- @param entity Entity Entity
--- @param status StatusAilment
--- @return boolean
function rt.has_status(entity, status)

    meta.assert_type(rt.Entity, entity, "has_status", 1)
    meta.assert_type(rt.StatusAilment, entity, "has_status", 2)

    return entity.status_ailments:contains(status)
end

--- @brief get id
--- @return BattleID
function rt.get_id(entity)

    meta.assert_type(rt.Entity, entity, "get_id", 1)

    return rt.BattleID({
        id = entity.id,
        name = entity.name,
        gender = entity.gender
    })
end

--- @brief get current hp value
--- @param entity Entity
--- @return Number
function rt.get_hp(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief get hp base
--- @param entity Entity
--- @return Number
function rt.get_hp_base(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief modify hp
--- @param entity Entity
--- @return Number
function rt.set_hp(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief add to hp, convenience function
--- @param entity Entity
--- @param value Number
function rt.add_hp(entity, value)
    rt.set_hp(entity, rt.get_hp(entity) + value)
end

--- @brief recude hp, convenience function
--- @param entity Entity
--- @param value Number
function rt.reduce_hp(entity, value)
    rt.set_hp(entity, rt.get_hp(entity) - value)
end

--- @brief get current hp value
--- @param entity Entity
--- @return Number
function rt.get_ap(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief get hp base
--- @param entity Entity
--- @return Number
function rt.get_ap_base(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief modify hp
--- @param entity Entity
--- @return Number
function rt.set_ap(entity)
    meta.assert_type(rt.Entity, entity)
    --- @todo
end

--- @brief add to hp, convenience function
--- @param entity Entity
--- @param value Number
function rt.add_ap(entity, value)
    rt.set_ap(entity, rt.get_ap(entity) + value)
end

--- @brief recude hp, convenience function
--- @param entity Entity
--- @param value Number
function rt.reduce_ap(entity, value)
    rt.set_ap(entity, rt.get_ap(entity) - value)
end

--- @brief getter: current attack
--- @param entity Entity
--- @return Number
function rt.get_attack(entity)
    meta.assert_type(rt.Entity, entity, "get_attack")

    local out = entity.base_attack * rt.stat_modifier_to_factor(entity.attack_level)

    for status in pairs(entity.status_ailments) do
        out = out * rt.status_ailment_to_attack_factor(status)
    end
    
    for _, effect in ipairs(entity.continuous_effects) do
        out = out * effect.attack_multiplier
    end

    return out
end

--- @brief getter: attack base
--- @param entity Entity
--- @return Number
function rt.get_attack_base(entity)
    meta.assert_type(rt.Entity, entity, "get_attack_base")
    return entity.base_attack
end

--- @brief getter: attack level
--- @param entity Entity
--- @return StatLevel
function rt.get_attack_level(entity)
    meta.assert_type(rt.Entity, entity, "get_attack_level")
    return entity.attack_level
end

--- @brief setter: attack modifier
--- @param entity Entity
--- @param modifier StatLevel
function rt.set_attack_level(entity, modifier)

    meta.assert_type(rt.Entity, entity, "set_attack_level", 1)
    meta.assert_enum(rt.StatLevel, modifier, "set_attack_level", 2)

    local current = rt.get_attack_level(entity)
    local next = modifier

    entity.attack_level = modifier;
    rt.log(rt.stat_modifier_changed_message(entity, rt.Attack, current, next))
end

--- @brief raise attack by 1
--- @param entity Entity
function rt.raise_attack_level(entity)
    meta.assert_type(rt.Entity, entity, "raise_attack_level", 1)

    local current = rt.get_attack_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MAX then
        --- @todo: log
        return
    end

    next = current + 1
    rt.set_attack_level(entity, next)
end

--- @brief lower attack by 1
--- @param entity Entity
function rt.lower_attack_level(entity)
    meta.assert_type(rt.Entity, entity, "lower_attack_level", 1)

    local current = rt.get_attack_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MIN then
        --- @todo: log
        return
    end

    next = current - 1
    rt.set_attack_level(entity, next)
end

--- @brief getter: current defense
--- @param entity Entity
--- @return Number
function rt.get_defense(entity)
    meta.assert_type(rt.Entity, entity, "get_defense")

    local out = entity.base_defense * rt.stat_modifier_to_factor(entity.defense_level)

    for status in pairs(entity.status_ailments) do
        out = out * rt.status_ailment_to_defense_factor(status)
    end

    for _, effect in ipairs(entity.continuous_effects) do
        out = out * effect.defense_multiplier
    end

    return out
end

--- @brief getter: defense base
--- @param entity Entity
--- @return Number
function rt.get_defense_base(entity)
    meta.assert_type(rt.Entity, entity, "get_defense_base")
    return entity.base_defense
end

--- @brief getter: defense level
--- @param entity Entity
--- @return StatLevel
function rt.get_defense_level(entity)
    meta.assert_type(rt.Entity, entity, "get_defense_level")
    return entity.defense_level
end

--- @brief setter: defense modifier
--- @param entity Entity
--- @param modifier StatLevel
function rt.set_defense_level(entity, modifier)

    meta.assert_type(rt.Entity, entity, "set_defense_level", 1)
    meta.assert_enum(rt.StatLevel, modifier, "set_defense_level", 2)

    local current = rt.get_defense_level(entity)
    local next = modifier

    entity.defense_level = modifier;
    rt.log(rt.stat_modifier_changed_message(entity, rt.Defense, current, next))
end

--- @brief raise defense by 1
--- @param entity Entity
function rt.raise_defense_level(entity)
    meta.assert_type(rt.Entity, entity, "raise_defense_level", 1)

    local current = rt.get_defense_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MAX then
        --- @todo: log
        return
    end

    next = current + 1
    rt.set_defense_level(entity, next)
end

--- @brief lower defense by 1
--- @param entity Entity
function rt.lower_defense_level(entity)
    meta.assert_type(rt.Entity, entity, "lower_defense_level", 1)

    local current = rt.get_defense_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MIN then
        --- @todo: log
        return
    end

    next = current - 1
    rt.set_defense_level(entity, next)
end

--- @brief getter: current speed
--- @param entity Entity
--- @return Number
function rt.get_speed(entity)
    meta.assert_type(rt.Entity, entity, "get_speed")

    local out = entity.base_speed * rt.stat_modifier_to_factor(entity.speed_level)

    for status in pairs(entity.status_ailments) do
        out = out * rt.status_ailment_to_speed_factor(status)
    end

    for _, effect in ipairs(entity.continuous_effects) do
        out = out * effect.speed_multiplier
    end

    return out
end

--- @brief getter: speed base
--- @param entity Entity
--- @return Number
function rt.get_speed_base(entity)
    meta.assert_type(rt.Entity, entity, "get_speed_base")
    return entity.base_speed
end

--- @brief getter: speed level
--- @param entity Entity
--- @return StatLevel
function rt.get_speed_level(entity)
    meta.assert_type(rt.Entity, entity, "get_speed_level")
    return entity.speed_level
end

--- @brief setter: speed modifier
--- @param entity Entity
--- @param modifier StatLevel
function rt.set_speed_level(entity, modifier)

    meta.assert_type(rt.Entity, entity, "set_speed_level", 1)
    meta.assert_enum(rt.StatLevel, modifier, "set_speed_level", 2)

    local current = rt.get_speed_level(entity)
    local next = modifier

    entity.speed_level = modifier;
    rt.log(rt.stat_modifier_changed_message(entity, rt.Speed, current, next))
end

--- @brief raise speed by 1
--- @param entity Entity
function rt.raise_speed_level(entity)
    meta.assert_type(rt.Entity, entity, "raise_speed_level", 1)

    local current = rt.get_speed_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MAX then
        --- @todo: log
        return
    end

    next = current + 1
    rt.set_speed_level(entity, next)
end

--- @brief lower speed by 1
--- @param entity Entity
function rt.lower_speed_level(entity)
    meta.assert_type(rt.Entity, entity, "lower_speed_level", 1)

    local current = rt.get_speed_level(entity)
    local next = rt.StatLevel.ZERO

    if current == rt.StatLevel.MIN then
        --- @todo: log
        return
    end

    next = current - 1
    rt.set_speed_level(entity, next)
end