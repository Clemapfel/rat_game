--- @class StatusAilment
rt.StatusAilment = meta.new_enum({
    DEAD = "DEAD",
    KNOCKED_OUT = "KNOCKED_OUT",
    NO_STATUS = "NO_STATUS",
    AT_RISK = "AT_RISK",
    STUNNED = "STUNNED",
    ASLEEP = "ASLEEP",
    POISONED = "POISONED",
    BLINDED = "BLINDED",
    BURNED = "BURNED",
    CHILLED = "CHILLED",
    FROZEN = "FROZEN"
})

--- @brief message when object gains status ailment
--- @param subject BattleID name of the subject
--- @param status_ailment StatusAilment
function rt.status_ailment_gained_message(subject, status_ailment)

    if not meta.isa(subject, rt.BattleID) then
        error("[ERROR] In status_ailment_gained_message: Argument #1 is not a string")
    end

    if not meta.is_enum_value(rt.StatusAIlment, status_ailment) then
        error("[ERROR] In status_ailment_gained_message: Argument #2 is not a StatusAilment")
    end

    local out = subject.name .. " "

    if status_ailment == rt.StatusAilment.DEAD then
        return out .. " died"
    elseif status_ailment == rt.StatusAilment.KNOCKED_OUT then
        return out .. " was knocked out"
    elseif status_ailment == rt.StatusAilment.AT_RISK then
        return out .. " is now at risk"
    elseif status_ailment == rt.StatusAilment.STUNNED then
        return out .. " is now stunned"
    elseif status_ailment == rt.StatusAilment.ASLEEP then
        return out .. " fell asleep"
    elseif status_ailment == rt.StatusAilment.POISONED then
        return out .. " was poisoned"
    elseif status_ailment == rt.StatusAilment.BLINDED then
        return out .. " was blinded"
    elseif status_ailment == rt.StatusAilment.BURNED then
        return out .. " started burning"
    elseif status_ailment == rt.StatusAilment.CHILLED then
        return out .. " was chilled"
    elseif status_ailment == rt.StatusAilment.FROZEN then
        return out .. " froze solid"
    else end
end

--- @brief message when object looses status ailment
--- @param subject string name of the subject
--- @param status_ailment StatusAilment
function rt.status_ailment_lost_message(subject, status_ailment)

    if not meta.isa(subject, rt.BattleID) then
        error("[ERROR] In status_ailment_lost_message: Argument #1 is not a string")
    end

    if not meta.is_enum_value(StatusAilment, status_ailment) then
        error("[ERROR] In status_ailment_lost_message: Argument #2 is not a StatusAilment")
    end

    local out = subject.name .. " "

    if status_ailment == rt.StatusAilment.DEAD then
        return out .. " came back from the dead"
    elseif status_ailment == rt.StatusAilment.KNOCKED_OUT then
        return out .. " is no longer knocked out"
    elseif status_ailment == rt.StatusAilment.AT_RISK then
        return out .. " is no longer at risk"
    elseif status_ailment == rt.StatusAilment.STUNNED then
        return out .. " is no longer stunned"
    elseif status_ailment == rt.StatusAilment.ASLEEP then
        return out .. " woke up"
    elseif status_ailment == rt.StatusAilment.POISONED then
        return out .. " is no longer poisoned"
    elseif status_ailment == rt.StatusAilment.BLINDED then
        return out .. " is no longer blinded"
    elseif status_ailment == rt.StatusAilment.BURNED then
        return out .. " is no longer burning"
    elseif status_ailment == rt.StatusAilment.CHILLED then
        return out .. " is no longer chilled"
    elseif status_ailment == rt.StatusAilment.FROZEN then
        return out .. " thawed"
    else end
end

