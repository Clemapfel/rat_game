--- @class StatModifier
rt.StatModifier = meta.new_enum({
    MIN = NEGATIVE_INFINITY,
    MINUS_4 = -4,
    MINUS_3 = -3,
    MINUS_2 = -2,
    MINUS_1 = -1,
    NONE = 0,
    PLUS_1 = 1,
    PLUS_2 = 2,
    PLUS_3 = 3,
    PLUS_4 = 4,
})

--- @brief convert modifier to numerical stat factor
--- @param modifier StatModifier
function rt.stat_modifier_to_factor(modifier)

    meta.assert_type(rt.StatModifier, modifier, "rt.state_modifier_to_factor", 1)

    if modifier == rt.StatModifier.MIN then
        return 0.0;
    elseif modifier == rt.StatModifier.MINUS_4 then
        return 1 / 8
    elseif modifier == rt.StatModifier.MINUS_3 then
        return 1 / 4
    elseif modifier == rt.StatModifier.MINUS_2 then
        return 1 / 2
    elseif modifier == rt.StatModifier.MINUS_1 then
        return 3 / 4
    elseif modifier == rt.StatModifier.ZERO then
        return 1
    elseif modifier == rt.StatModifier.PLUS_1 then
        return 1.25
    elseif modifier == rt.StatModifier.PLUS_2 then
        return 1.5
    elseif modifier == rt.StatModifier.PLUS_3 then
        return 2
    elseif modifier == rt.StatModifier.PLUS_4 then
        return 3
    end
end

--- @brief message when stat is raised
--- @param subject BattleID
--- @param state string stat name, for example "Attack"
--- @param current_modifier StatModifier current modifier
--- @param next_modifier StatModifier newly to-apply modifier
function rt.stat_modifier_change_message(subject, stat, current_modifier, next_modifier)

    -- todo
    if not meta.isa(subject, rt.BattleID) then
        error("[ERROR] In stat_modifier_increase_message: Argument #1 is not a string")
    end

    if not meta.isa(subject, rt.BattleID) then
        error("[ERROR] In stat_modifier_increase_message: Argument #2 is not a string")
    end

    if not meta.is_enum_value(rt.StatModifier, modifier) then
        error("[ERROR] In stat_modifier_increase_message: Argument #3 is not a StatusAilment")
    end

    if not meta.is_enum_value(rt.StatModifier, modifier) then
        error("[ERROR] In stat_modifier_increase_message: Argument #4 is not a StatusAilment")
    end

    if (current_modifier == next_modifier) then
        return id.name .. "s " .. stat .. " remained unchanged"
    end

    if (next_modifier == rt.StatModifier.NONE) then
        return id.name .. "s " .. stat .. " was reset" -- TODO: phrasing
    end

    if (next_modifier == rt.StatModifier.MIN) then
        return id.name .. "s " .. stat .. " was minimized" -- TODO: phrasing
    end

    local delta = math.abs(current_modifier - next_modifier)
    local out = id.name .. "s " .. state

    if (current_modifier < next_modifier) then
        if delta == 1 then
            return out .. " was lowered"
        elseif delta == 2 then
            return out .. " was sharply lowered"
        else
            return out .. " was drastically lowered"
        end
    elseif (current_modifier > next_modifier) then
        if delta == 1 then
            return out .. " grew"
        elseif delta == 2 then
            return out .. " grew sharply"
        else
            return out .. " grew drastically"
        end
    end
end