--- @class BattleContinuousEffect
rt.BattleContinuousEffect = meta.new_type("BattleContinuousEffect", {
    
    id = "",
    attack_multiplier = meta.Number(1),
    defense_multiplier = meta.Number(1),
    speed_multiplier = meta.Number(1),
    hp_multiplier = meta.Number(1),
    ap_multiplier = meta.Number(1)
})

--- @class BattleEntity
rt.BattleEntity = meta.new_type("BattleEntity", {

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

    attack_level = rt.StatModifier.NONE,
    defense_level = rt.StatModifier.NONE,
    speed_level = rt.StatModifier.NONE,

    status_ailments = Set(),
    continuous_effects = Set()
})

meta.set_constructor(rt.BattleEntity, function(this, id)
    local out = meta.new(rt.BattleEntity)
    out.id = id
    out.name = id
    return out
end)

--- @brief does entity have status
--- @param entity BattleEntity BattleEntity
--- @param status StatusAilment
--- @return boolean
function rt.has_status(entity, status)

    meta.assert_type(rt.BattleEntity, entity, "has_status", 1)
    meta.assert_type(rt.StatusAilment, entity, "has_status", 2)

    return entity.status_ailments:contains(status)
end

--- @brief get id
--- @return BattleID
function rt.get_id(entity)

    meta.assert_type(rt.BattleEntity, entity, "get_id", 1)

    return rt.BattleID({
        id = entity.id,
        name = entity.name,
        gender = entity.gender
    })
end

--- @brief getter: current attack
--- @param entity BattleEntity
--- @return number
function rt.get_attack(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_attack")

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
--- @param entity BattleEntity
--- @return number
function rt.get_attack_base(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_attack_base")
    return entity.base_attack
end

--- @brief getter: attack base
--- @param entity BattleEntity
--- @return StatModifier
function rt.get_attack_level(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_attack_level")
    return entity.attack_level
end

--- @brief getter: current defense
--- @param entity BattleEntity
--- @return number
function rt.get_defense(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_defense")

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
--- @param entity BattleEntity
--- @return number
function rt.get_defense_base(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_defense_base")
    return entity.base_defense
end

--- @brief getter: defense base
--- @param entity BattleEntity
--- @return StatModifier
function rt.get_defense_level(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_defense_level")
    return entity.defense_level
end

--- @brief getter: current speed
--- @param entity BattleEntity
--- @return number
function rt.get_speed(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_speed")

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
--- @param entity BattleEntity
--- @return number
function rt.get_speed_base(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_speed_base")
    return entity.base_speed
end

--- @brief getter: speed base
--- @param entity BattleEntity
--- @return StatModifier
function rt.get_speed_level(entity)
    meta.assert_type(rt.BattleEntity, entity, "get_speed_level")
    return entity.speed_level
end

--- @brief setter: attack modifier
--- @param entity BattleEntity
--- @param modifier StatModifier
function rt.set_attack_level(entity, modifier)

    meta.assert_type(rt.BattleEntity, entity, "set_attack_level", 1)
    meta.assert_enum(rt.StatModifier, modifier, "set_attack_level", 2)

    local current = rt.get_attack_level(entity)
    local next = modifier

    entity.attack_level = modifier;
    log.message(rt.stat_modifier_changed_message(entity, rt.Attack, current, next))
end

--- @brief setter: attack modifier
--- @param entity BattleEntity
--- @param modifier StatModifier
function rt.set_defense_level(entity, modifier)

    meta.assert_type(rt.BattleEntity, entity, "set_defense_level", 1)
    meta.assert_enum(rt.StatModifier, modifier, "set_defense_level", 2)

    local current = rt.get_defense_level(entity)
    local next = modifier

    entity.defense_level = modifier;
    log.message(rt.stat_modifier_changed_message(entity, rt.Defense, current, next))
end

--- @brief setter: attack modifier
--- @param entity BattleEntity
--- @param modifier StatModifier
function rt.set_speed_level(entity, modifier)

    meta.assert_type(rt.BattleEntity, entity, "set_speed_level", 1)
    meta.assert_enum(rt.StatModifier, modifier, "set_speed_level", 2)

    local current = rt.get_speed_level(entity)
    local next = modifier

    entity.speed_level = modifier;
    log.message(rt.stat_modifier_changed_message(entity, rt.Speed, current, next))
end