--- @class ContinuousEffect
rt.ContinuousEffect = meta.new_type("ContinuousEffect", {

    id = "",
    name = "",

    duration = POSITIVE_INFINITY,

    hp_multiplier = meta.Number(1),
    hp_offset = meta.Number(0),

    ap_multiplier = meta.Number(1),
    ap_offset = meta.Number(0),

    attack_multiplier = meta.Number(1),
    attack_offset = meta.Number(0),

    defense_multiplier = meta.Number(1),
    defense_offset = meta.Number(0),

    speed_multiplier = meta.Number(1),
    speed_offset = meta.Number(0),

    on_damage_taken = rt.IgnitionEffect(),
    on_damage_dealt = rt.IgnitionEffect(),

    on_move_used = rt.IgnitionEffect(),

    --- @brief (BattleEntity self) -> string
    status_gained_message = function(self)
        return nil
    end,

    --- @brief (BattleEntity self) -> string
    status_lost_message = function(self)
        return nil
    end
})

rt.ContinuousEffect.__meta.__eq = function(self, other)
    return self.id == other.id
end

--- @brief add continuous effect
--- @param id string
--- @param arguments table
rt.ContinuousEffects = {}
function rt.new_continuous_effect(id, args)
    args[id] = id
    rt.ContinuousEffects[id] = meta.new(rt.ContinuousEffects, args)

end

--- @brief add to entity
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.add_continuous_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "add_continuous_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "add_continuous_effect", 2)

    if entity.continuous_effects:insert(effect) then
        log.message(effect.status_gained_message(entity))
    end
end

--- @brief check if effect is present
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.has_continuous_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "has_continuous_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "has_continuous_effect", 2)

    for value in pairs(entity.continuous_effects) do
        if value.id == effect.id then
            return true
        end
    end
    return false
end

--- @brief remove effect
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.remove_conitnuous_effect(entity, effect)
    meta.assert_type(rt.Entity, entity, "has_continuous_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "has_continuous_effect", 2)

    for value in pairs(entity.continuous_effects) do
        if value.id == effect.id then
            entity.continuous_effects:erase(effect)
            log.message(effect.status_lost_message(entity))
            return
        end
    end
end

--[[
test = {
    AT_RISK = "AT_RISK",
    STUNNED = "STUNNED",
    ASLEEP = "ASLEEP",
    POISONED = "POISONED",
    BLINDED = "BLINDED",
    BURNED = "BURNED",
    CHILLED = "CHILLED",
    FROZEN = "FROZEN"
}
]]--

--- @brief StatusAilment: at risk
rt.new_continuous_effect("at_risk", {

    on_damage_taken = function(self)
        rt.set_status(self, rt.StatusAilment.DEAD)
    end,

    status_gained_message = function(self)
        return self.name .. " is now at risk"
    end,

    status_lost_message = function(self)
        return self.name .. " is no longer at risk"
    end
})






