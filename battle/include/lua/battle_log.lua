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

--- @brief he/she/it/they
--- @param id BattleID
function rt.subject_pronoun(id)

    if not meta.isa(id, "BattleID") then
        error("[ERROR] In subject_pronoun: Argument #1 is not a BattleID")
    end

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

    if not meta.isa(id, "BattleID") then
        error("[ERROR] In object_pronoun: Argument #1 is not a BattleID")
    end

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

    if not meta.isa(id, rt.BattleID) then
        error("[ERROR] In object_pronoun: Argument #1 is not a BattleID")
    end

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

    if not meta.isa(id, "BattleID") then
        error("[ERROR] In object_pronoun: Argument #1 is not a BattleID")
    end

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
