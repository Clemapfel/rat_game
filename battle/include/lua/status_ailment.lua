--- @class StatusAilment
rt.StatusAilment = meta.new_enum({
    DEAD = "DEAD",
    KNOCKED_OUT = "KNOCKED_OUT",
    ALIVE = "ALIVE",
})

--- @brief get attack modifier of status ailment
--- @param status StatusAilment
--- @return number
function rt.status_ailment_to_attack_multiplier(status)
    
    meta.assert_type(rt.StatusAilment, status, "status_ailment_to_attack_multiplier")

    if status == StatusAilment.BLINDED then
        return 0
    elseif status == StatusAilment.BURNED then
        return 0.5
    end
        
    return 1
end

--- @brief get defense modifier of status ailment
--- @param status StatusAilment
--- @return number
function rt.status_ailment_to_defense_multiplier(status)

    meta.assert_type(rt.StatusAilment, status, "status_ailment_to_defense_multiplier")

    if status == StatusAilment.ASLEEP then
        return 0.5
    end
    
    return 1
end

--- @brief get speed modifier of status ailment
--- @param status StatusAilment
--- @return number
function rt.status_ailment_to_speed_multiplier(status)

    meta.assert_type(rt.StatusAilment, status, "status_ailment_to_speed_multiplier")
    
    if status == StatusAilment.CHILLED then
        return 0.5
    elseif status == StatusAilment.FROZEN then
        return 0
    end
        
    return 1
end

--- @brief message when object gains status ailment
--- @param subject BattleID name of the subject
--- @param status_ailment StatusAilment
function rt.status_ailment_gained_message(subject, status_ailment)

    meta.assert_type(rt.Entity, subject)
    meta.assert_enum(rt.StatusAilment, status_ailment)

    local out = rt.get_id(subject).name .. " "

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

    meta.assert_type(rt.Entity, subject)
    meta.assert_enum(rt.StatusAilment, status_ailment)

    local out = rt.get_id(subject).name .. " "

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

