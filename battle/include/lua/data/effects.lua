
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

--- @brief marks entity, any damage dealt to it kills it instantly
rt.AT_RISK = rt.new_effect("at_risk", {

    duration = 3,

    after_taking_damage = rt.IgnitionEffect(function(self, other, damage)
        self.set_status(DEAD)
        return self.name .. " was executed"
    end),

    on_status_gained = function(self)
        return self.name .. " is now at risk"
    end,

    on_status_lost = function(self)
        return self.name .. " is no longer at risk"
    end
})

--- @brief take 1/16 of base hp per round
rt.POISONED = rt.new_effect("poisoned", {

    duration = POSITIVE_INFINITY,

    on_turn_end = rt.IgnitionEffect(function(self)
        rt.reduce_hp(1/8 * rt.get_hp_base(self))
        return self.name .. " was hurt by poison"
    end),

    on_status_gained = function(self)
        return self.name .. " was poisoned"
    end,

    on_status_lost = function(self)
        return self.name .. " is no longer poisoned"
    end
})

--- @brief reduce attack, take 1/16 of base hp per round
rt.BURNED = rt.new_effect("burned", {

    duration = 3,
    attack = 0.5,

    on_turn_end = function(self)
        rt.reduce_hp(self, 1/16 * rt.get_hp_based(self))
        return self.name .. "is hurt by the flames"
    end,

    on_status_gained = function(self)
        return self.name .. " combusted into flames and is now burning"
    end,

    on_status_lost = function(self)
        return self.name .. " is no longer poisoned"
    end
})

--- @brief make all damage deal to
rt.BLINDED = rt.new_effect("blinded", {

    duration = 3,
    attack_factor = 0.01,

    on_status_gained = function(self)
        return self.name .. " was temporarily blinded"
    end,

    on_status_lost = function(self)
        return self.name .. " is no longer blinded and can see clearly again"
    end
})

--- @brief StatusAilment:
rt.FROZEN = rt.new_effect("frozen", {

    duration = 5,
    speed_factor = 0.5,

    on_status_gained = function(self)
        return self.name .. " froze solid"
    end,

    on_status_lost = function(self)
        return self.name .. " thawed and is no longer frozen"
    end
})

--- @brief chill
rt.CHILLED = rt.new_effect("chilled", {

    duration = POSITIVE_INFINITY,
    speed_factor = 0.5,

    on_status_gained = function(self)
        if rt.has_effect(rt.CHILED) then
            rt.remove_effect(self, rt.CHILLD)
            rt.add_effect(self, rt.FROZEN)
        end
        return self.name .. " is now chillid"
    end,

    on_status_lost = function(self)
        return self.name .. " is now chillid"
    end
})

---  @brief stuns enemy for 1 round
