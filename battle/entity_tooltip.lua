rt.settings.entity_tooltip = {
    no_status_label = "none",
    status_prefix = "<b>Status Effects:</b> ",
    status_duration_prefix = "  <color=GRAY_2>(<mono>",
    status_duration_suffix = "</mono> turns left)</color>"
}

--- @class bt.EntityTooltip
bt.EntityTooltip = meta.new_type("EntityTooltip", function(entity)
    meta.assert_entity(entity)
    local out = meta.new(bt.EntityTooltip, {
        _entity = entity,
        _tooltip = {} -- bt.BattleTooltip
    }, rt.Widget, rt.Drawable)

    out._tooltip = bt.BattleTooltip(
        out._entity.name,
        out:_format_stat_label(),
        out:_format_status_ailment_label(),
        out._entity.description
    )

    return out
end)

bt.EntityTooltip._censor_attack = true
bt.EntityTooltip._censor_defense = false
bt.EntityTooltip._censor_speed = true
bt.EntityTooltip._censor_hp = true

--- @overload rt.Widget.get_top_level_widget
function bt.EntityTooltip:get_top_level_widget()
    return self._tooltip:get_top_level_widget()
end

--- @brief [internal]
function bt.EntityTooltip:_format_stat_label()

    local level_to_arrow = function(level)
        if level > 0 then
            return string.rep("+", level)
        elseif level < 0 then
            return string.rep("-", math.abs(level))
        else
            return ""
        end
    end

    local get_n_digits = function(x)
        if x < 0 then x = math.abs(x) end
        if x == 0 then return 1 end
        return math.floor(math.log(x, 10)) + 1 + ternary(x < 0, 1, 0)
    end

    local hp = self._entity:get_hp()
    local attack = self._entity:get_attack()
    local defense = self._entity:get_defense()
    local speed = self._entity:get_speed()

    local n_digits = 0
    for _, modifier in pairs({hp, attack, defense, speed}) do
        n_digits = math.max(n_digits, get_n_digits(modifier))
    end

    local stat_to_label = function(label, stat, level, censor)
        local offset = ""
        for i = 1, n_digits - get_n_digits(stat) do
            offset = offset .. " "
        end

        local prefix = "<mono>"
        if level ~= 0 then prefix = prefix .. "" end

        local suffix = ""
        if level ~= 0 then suffix = suffix .. " " .. level_to_arrow(level) .. "" end
        suffix = suffix .. "</mono>"

        local stat_label = tostring(stat)

        return prefix .. label .. ": " .. offset .. ternary(censor, string.rep("?", #stat_label), stat_label) .. suffix
    end

    local out = ""

    out = out .. "<color=HP>" .. stat_to_label("HP ", hp, 0, self._censor_hp) .. "</color>\n"
    out = out .. "<color=ATTACK>" .. stat_to_label("ATK", attack, self._entity:get_attack_level(), self._censor_attack) .. "</color>\n"
    out = out .. "<color=DEFENSE>" .. stat_to_label("DEF", defense, self._entity:get_defense_level(), self._censor_defense) .. "</color>\n"
    out = out .. "<color=SPEED>" .. stat_to_label("SPD", speed, self._entity:get_speed_level(), self._censor_speed) .. "</color>\n"

    return out
end

--- @brief [internal]
function bt.EntityTooltip:_format_status_ailment_label()

    if sizeof(self._entity.status_ailments) == 0 then
        return rt.settings.entity_tooltip.status_prefix .. rt.settings.entity_tooltip.no_status_label
    end

    local out = rt.settings.entity_tooltip.status_prefix .. "\n"
    for status, _ in pairs(self._entity.status_ailments) do
        out = out .. "\t" .. status.name;
        if status.max_duration < POSITIVE_INFINITY then
            local left = status.max_duration - self._entity:_get_status_ailment_elapsed(status)
            out = out .. rt.settings.entity_tooltip.status_duration_prefix .. tostring(left) .. rt.settings.entity_tooltip.status_duration_suffix .. "\n"
        end
    end
    return out
end