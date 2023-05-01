--- @class GrammaticGender
rt.GrammaticGender = meta.new_enum({
    MALE = "MALE",
    FEMALE = "FEMALE",
    NEUTRAL = "NEUTRAL",
    PLURAL = "PLURAL"
})

--- @class BattleID
rt.BattleID = meta.new_type("BattleID", {
    id = "",
    name = "",
    gender = rt.GrammaticGender.NEUTRAL
})

rt._log_muted = false
rt._animations_muted = false

--- @brief message
function rt.log(message)
    if not rt._log_muted then
        print("[LOG] ", message, "\n")
    end
end

--- @brief mute all messages until unmute_log is called
function rt.mute_log()
    rt._log_muted = true
end

--- @brief unmute log
function rt.unmute_log()

    if rt._log_muted == false then
        print("[WARNING] IN rt.unmute_log: Log is not currently muted")
    end
    rt._log_muted = false
end

--- @brief prevent all animations until unmuate_animations is called
function rt.mute_animations()
    rt._animations_muted = true
end

--- @brief unmute animations
function rt.unmute_animations()

    if rt._animations_muted == false then
        print("[WARNING] IN rt.unmute_log: Log is not currently muted")
    end
    rt._animations_unmuted = false
end

--- @brief he/she/it/they
--- @param id BattleID
function rt.subject_pronoun(id)

    meta.assert_type(rt.Entity, id)

    if id.gender == rt.GrammaticGender.MALE then
        return "he"
    elseif id.gender == rt.GrammaticGender.FEMALE then
        return "she"
    elseif id.gender == rt.GrammaticGender.THING then
        return "it"
    elseif id.gender == rt.GrammaticGender.PLURAL then
        return "they"
    end
end

--- @brief him/her/it/the
--- @param id BattleID
function rt.object_pronoun(id)

    meta.assert_type(rt.Entity, id)

    if id.gender == rt.GrammaticGender.MALE then
        return "him"
    elseif id.gender == rt.GrammaticGender.FEMALE then
        return "her"
    elseif id.gender == rt.GrammaticGender.THING then
        return "it"
    elseif id.gender == rt.GrammaticGender.PLURAL then
        return "them"
    end
end

--- @brief his/her/its/their
--- @param id BattleID
function rt.possesive_pronoun(id)

    meta.assert_type(rt.Entity, id)

    if id.gender == rt.GrammaticGender.MALE then
        return "his"
    elseif id.gender == rt.GrammaticGender.FEMALE then
        return "her"
    elseif id.gender == rt.GrammaticGender.THING then
        return "its"
    elseif id.gender == rt.GrammaticGender.PLURAL then
        return "their"
    end
end

--- @brief himself/herself/iself/themself
--- @param id BattleID
function rt.reflexive_pronoun(id)

    meta.assert_type(rt.Entity, id)

    if id.gender == rt.GrammaticGender.MALE then
        return "himself"
    elseif id.gender == rt.GrammaticGender.FEMALE then
        return "herself"
    elseif id.gender == rt.GrammaticGender.THING then
        return "itself"
    elseif id.gender == rt.GrammaticGender.PLURAL then
        return "themself"
    end
end

