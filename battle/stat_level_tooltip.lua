--- @class Stat
bt.Stat = meta.new_enum({
    ATTACK = "ATTACK",
    DEFENSE = "DEFENSE",
    SPEED = "SPEED"
})

--- @class bt.StatLevelIndicator
bt.StatLevelIndicator = meta.new_type("StatLevelIndicator", function(level, which)
    if meta.is_nil(bt.PartyInfo.spritesheet) then
        bt.StatLevelIndicator.spritesheet = rt.Spritesheet("assets/sprites", "party_info")
    end

    local out = meta.new(bt.StatLevelIndicator, {
        _sprite = rt.Sprite(bt.StatLevelIndicator.spritesheet , "neutral")
    }, rt.Drawable, rt.Widget)
    out:set_level(level)

    if not meta.is_nil(which) and level ~= 0 then
        out._sprite:set_color(rt.Palette[which])
    end
    return out
end)

--- @overload
function bt.StatLevelIndicator:get_top_level_widget()
    return self._sprite
end

function bt.StatLevelIndicator:draw()
    self._sprite:draw()
end

--- @brief
function bt.StatLevelIndicator:set_level(level)
    local id = "neutral"
    if level > 3 then
        id = "up_infinite"
    elseif level == 3 then
        id = "up_3"
    elseif level == 2 then
        id = "up_2"
    elseif level == 1 then
        id = "up_1"
    elseif level == 0 then
        id = "neutral"
    elseif level == -1 then
        id = "down_1"
    elseif level == -2 then
        id = "down_2"
    elseif level == -3 then
        id = "down_3"
    elseif level < -3 then
        id = "down_infinite"
    end

    self._sprite:set_animation(id)
end

--- @class bt.StatLevelTooltip
bt.StatLevelTooltip = meta.new_type("StatLevelTooltip", function(which, level)

    meta.assert_enum(which, bt.Stat)
    local out = meta.new(bt.StatLevelTooltip, {
        _level = level,
        _which = which,
        _sprite = bt.StatLevelIndicator(level, which),
        _tooltip = {} -- bt.BattleTooltip
    }, rt.Widget, rt.Drawable)

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
    return self._tooltip:get_top_level_widget()
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
