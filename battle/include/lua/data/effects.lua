--- @brief marks entity, any damage dealt to it kills it instantly
rt.AT_RISK = rt.new_effect("at_risk", {

    duration = 3,

    on_damage_taken = function(self, other, damage)
        self.set_status(DEAD)
        rt.log(self.name .. " was executed")
    end,

    on_status_gained = function(self)
        rt.log(self.name .. " is now at risk")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is no longer at risk")
    end,

    description = "TODO"
})

--- @brief take 1/16 of base hp per round
rt.POISONED = rt.new_effect("poisoned", {

    duration = POSITIVE_INFINITY,

    on_turn_end = function(self)
        rt.reduce_hp(1/8 * rt.get_hp_base(self))
        rt.log(self.name .. " was hurt by poison")
    end,

    on_status_gained = function(self)
        rt.log(self.name .. " was poisoned")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is no longer poisoned")
    end,

    description = "TODO"
})

--- @brief reduce attack, take 1/16 of base hp per round
rt.BURNED = rt.new_effect("burned", {

    duration = 3,
    attack_factor = 0.5,

    on_turn_end = function(self)
        rt.reduce_hp(self, 1/16 * rt.get_hp_based(self))
        rt.log(self.name .. "is hurt by the flames")
    end,

    on_status_gained = function(self)
        rt.log(self.name .. " combusted into flames and is now burning")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is no longer poisoned")
    end,

    description = "TODO"
})

--- @brief make all damage deal to
rt.BLINDED = rt.new_effect("blinded", {

    duration = 3,
    attack_factor = 0.01,

    on_status_gained = function(self)
        rt.log(self.name .. " was temporarily blinded")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is no longer blinded and can see clearly again")
    end,

    description = "TODO"
})

--- @brief StatusAilment:
rt.FROZEN = rt.new_effect("frozen", {

    duration = 5,
    speed_factor = 0.5,

    on_status_gained = function(self)
        rt.log(self.name .. " froze solid")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " thawed and is no longer frozen")
    end,

    description = "TODO"
})

--- @brief chill
rt.CHILLED = rt.new_effect("chilled", {

    duration = POSITIVE_INFINITY,
    speed_factor = 0.5,

    on_status_gained = function(self)
        if rt.has_effect(rt.CHILLED) then
            rt.remove_effect(self, rt.CHILLD)
            rt.add_effect(self, rt.FROZEN)
            return
        end
        rt.log(self.name .. " is now chilled")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is now chilled")
    end,

    description = "TODO"
})

--- @brief stuns enemy for 1 round
rt.STUNNED = rt.new_effect("stunned", {

    duration = 1,
    is_stun = true,

    on_status_gained = function(self)
        rt.log(self.name .. " was stunned")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " is no longer stunned")
    end
})

--- @brief sleep: wake up if damaged
rt.ASLEEP = rt.new_effect("asleep", {

    duration = 3,
    is_stun = true,
    
    on_damage_taken = function(self, damage)
        rt.reduce_hp(self, damage * 0.5)
        rt.log(self.name .. " was surprised in " .. log.possesive_pronoun(self))
        rt.remove_effect(self, rt.ASLEEP)
    end,

    on_status_gained = function(self)
        rt.log(self.name .. " fell asleep")
    end,

    on_status_lost = function(self)
        rt.log(self.name .. " woke up")
    end,

    description = "TODO"
})

--- @brief unaware: ignore enemy buffs (but not debuffs)
rt.UNAWARE = rt.new_effect("unaware", {

    before_damage_taken = function(self, other)
        rt.mute_log()
        rt.mute_animations()

        rt.UNAWARE._previous_attack = rt.get_attack_level(other)
        rt.UNAWARE._previous_defense = rt.get_defense_level(other)
        rt.UNAWARE._previous_speed = rt.get_speed_level(other)

        if rt.get_attack_level(other) > 0 then
            rt.set_attack_level(other, rt.StatLevel.ZERO)
        end

        if rt.get_defense_level(other) > 0 then
            rt.set_defense_level(other, rt.StatLevel.ZERO)
        end

        if rt.get_speed_level(other) > 0 then
            rt.set_speed_level(other, rt.StatLevel.ZERO)
        end

        rt.unmute_log()
        rt.unmute_animations()
    end,

    on_damage_taken = function(self, other, damage)

        rt.mute_log()
        rt.mute_animations()

        rt.set_attack_level(other, rt.UNAWARE._previous_attack)
        rt.set_defense_level(other, rt.UNAWARE._previous_defense)
        rt.set_speed_level(other, rt.UNAWARE._previous_speed)

        rt.UNAWARE._previous_attack = nil
        rt.UNAWARE._previous_defense = nil
        rt.UNAWARE._previous_speed = nil

        rt.unmute_log()
        rt.unmute_animations()
    end,

    description = "TODO"
})