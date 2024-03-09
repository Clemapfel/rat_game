--- @class bt.StatLevelTooltip
bt.StatLevelTooltip = meta.new_type("StatLevelTooltip", rt.Widget, function(which, level)

    meta.assert_enum(which, bt.Stat)
    local out = meta.new(bt.StatLevelTooltip, {
        _level = level,
        _which = which,
        _sprite = bt.StatLevelIndicator(level, which),
        _tooltip = {} -- bt.BattleTooltip
    })

    local title = "Stat Level "

    if level == 0 then
        title = title .. "<mono>±" .. tostring(level) .. "</mono>"
    elseif level <= 3 and level >= 1 then
        title = title .. "<mono>+" .. tostring(level) .. "</mono>"
    elseif level >= -3 and level <= - 1 then
        title = title .. "<mono>" .. tostring(level) .. "</mono>"
    elseif level >= 4 then
        title = title .. "∞"
    elseif level <= -4 then
        title = title .. "<mono>0</mono>"
    end

    title = title

    out._tooltip = bt.BattleTooltip(
        title,
        out:_format_stat_level_description(),
        nil,
        nil,
        out._sprite._sprite
    )
    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.StatLevelTooltip:get_top_level_widget()
    return self._tooltip
end

--- @brief
function bt.StatLevelTooltip:_format_stat_level_description()

    local function format_percentage(x)
        if x < 1 then
            return "-" .. tostring(math.abs(x - 1) * 100) .. "%"
        else
            return "+" .. tostring((x - 1) * 100) .. "%"
        end
    end

    local stat = "ERROR"
    if self._which == bt.Stat.ATTACK then
        stat = "<color=ATTACK>ATK</color>"
    elseif self._which == bt.Stat.DEFENSE then
        stat = "<color=DEFENSE>DEF</color>"
    elseif self._which == bt.Stat.SPEED then
        stat = "<color=SPEED>SPD</color>"
    end

    stat = "<b><o>" .. stat .. "</o></b>"

    if self._level == 0 then
        return stat .. " is <b>unchanged</b>."
    elseif self._level >= 4 then
        return stat .. " is treated as <b>infinity</b>."
    elseif self._level <= -4 then
        return stat .. " is treated as <b><mono>0</mono></b>."
    elseif self._level > 0 then
        return stat .. " is <b>raised</b> by <mono>" .. format_percentage(bt.stat_level_to_factor(self._level)) .. "</mono>."
    elseif self._level < 0 then
        return stat .. " is <b>lowered</b> by <mono>" .. format_percentage(bt.stat_level_to_factor(self._level)) .. "</mono>."
    end
end
