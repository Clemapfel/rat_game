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
    else
        error("[ERROR] In stat_level_to_factor: Unreachable reached")
    end
end
