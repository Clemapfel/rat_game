--- @class StatLevel
rt.StatLevel = meta.new_enum({
    MIN = -5,
    MINUS_4 = -4,
    MINUS_3 = -3,
    MINUS_2 = -2,
    MINUS_1 = -1,
    ZERO = 0,
    PLUS_1 = 1,
    PLUS_2 = 2,
    PLUS_3 = 3,
    PLUS_4 = 4,
    MAX = 5
})

rt.Attack = "Attack"
rt.Defense = "Defense"
rt.Speed = "Speed"

--- @brief convert level to numerical stat factor
--- @param level StatLevel
function rt.stat_level_to_factor(level)

    meta.assert_enum(rt.StatLevel, level, "stat_level_to_factor", 1)

    if level == rt.StatLevel.MIN then
        return 0.0;
    elseif level == rt.StatLevel.MINUS_4 then
        return 1 / 8
    elseif level == rt.StatLevel.MINUS_3 then
        return 1 / 4
    elseif level == rt.StatLevel.MINUS_2 then
        return 1 / 2
    elseif level == rt.StatLevel.MINUS_1 then
        return 3 / 4
    elseif level == rt.StatLevel.ZERO then
        return 1
    elseif level == rt.StatLevel.PLUS_1 then
        return 1.25
    elseif level == rt.StatLevel.PLUS_2 then
        return 1.5
    elseif level == rt.StatLevel.PLUS_3 then
        return 2
    elseif level == rt.StatLevel.PLUS_4 then
        return 3
    elseif level == rt.StatLevel.MAX then
        return 4
    end
end


--- @brief message when stat is raised
--- @param subject BattleID
--- @param state string stat name, for example "Attack"
--- @param current_level StatLevel current level
--- @param next_level StatLevel newly to-apply level
function rt.stat_level_changed_message(subject, stat, current_level, next_level)

    meta.assert_type(rt.Entity, subject)
    meta.assert_enum(rt.StatLevel, current_level)
    meta.assert_enum(rt.StatLevel, next_level)

    local id = rt.get_id(subject)

    if (current_level == next_level) then
        return id.name .. "s " .. stat .. " remained unchanged"
    end

    if (next_level == rt.StatLevel.ZERO) then
        return id.name .. "s " .. stat .. " was reset" -- TODO: phrasing
    end

    if (next_level == rt.StatLevel.MIN) then
        return id.name .. "s " .. stat .. " was minimized" -- TODO: phrasing
    end

    local delta = math.abs(current_level - next_level)
    local out = id.name .. "s " .. stat

    if (current_level > next_level) then
        if delta == 1 then
            return out .. " was lowered"
        elseif delta == 2 then
            return out .. " was sharply lowered"
        else
            return out .. " was drastically lowered"
        end
    elseif (current_level < next_level) then
        if delta == 1 then
            return out .. " grew"
        elseif delta == 2 then
            return out .. " grew sharply"
        else
            return out .. " grew drastically"
        end
    end
end
