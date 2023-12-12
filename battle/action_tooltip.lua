rt.settings.action_tooltip = {
    target_prefix = "<b>Targets:</b> ",
    effect_prefix = "<u><b>Effect</b></u>: ",
    n_uses_prefix = "<b>PP: </b>",
    infinity_uses_label = "―――"
}

--- @class bt.ActionTooltip
bt.ActionTooltip = meta.new_type("ActionTooltip", function(action)

    local sprite_id = "dusk"
    local out = meta.new(bt.ActionTooltip, {
        _action = action,
        _tooltip = {} -- bt.BattleTooltip
    }, rt.Widget, rt.Drawable)

    out._tooltip = bt.BattleTooltip(
        out._action.name,
        out:_format_target_label(),
        rt.settings.action_tooltip.effect_prefix .. out._action.verbose_effect_text,
        out._action.flavor_text,
        action:create_sprite()
    )

    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.ActionTooltip:get_top_level_widget()
    return self._tooltip:get_top_level_widget()
end

--- @brief [internal]
function bt.ActionTooltip:_format_target_label()

    self = self._action
    local me, enemy, ally = self.can_target_self, self.can_target_enemy, self.can_target_ally

    local function _ally(str)
        return "<color=ALLY>" .. str .. "</color>"
    end

    local function _enemy(str)
        return "<color=ENEMY>" .. str .. "</color>"
    end

    local function _me(str)
        return "<color=SELF>" .. str .. "</color>"
    end

    local function _field()
        return "<color=GREY_2>" .. " ――― " .. "</color>"
    end

    local function _everyone(str)
        return "<color=FIELD>" .. str .. "</color>"
    end

    local out = ""

    if self.targeting_mode == bt.TargetingMode.SINGLE then
        if         me and not ally and not enemy then
            out = _me("self")
        elseif     me and     ally and     enemy then
            out = _me("self") .. " or " .. _ally("single ally") .. " or " .. _enemy("single enemy")
        elseif     me and     ally and not enemy then
            out = _me("self") .. " or " .. _ally("single ally")
        elseif     me and not ally and     enemy then
            out = _me("self") .. " or " .. _enemy("single enemy")
        elseif not me and     ally and not enemy then
            out = _ally("single ally")
        elseif not me and not ally and     enemy then
            out = _enemy("single enemy")
        elseif not me and     ally and     enemy then
            out = _ally("single ally") .. " or " .. _enemy("single enemey")
        elseif not me and not ally and not enemy then
            out = _field()
        end
    elseif self.targeting_mode == bt.TargetingMode.MULTIPLE then
        if         me and not ally and not enemy then
            out = _me("self")
        elseif     me and     ally and     enemy then
            out = _everyone("everyone")
        elseif     me and     ally and not enemy then
            out = _ally("self and all allies")
        elseif     me and not ally and     enemy then
            out = _me("self") .. " and " .. _enemy("all enemies")
        elseif not me and     ally and not enemy then
            out = _ally("entire party") .. " except " .. _me("self")
        elseif not me and not ally and     enemy then
            out = _enemy("all enemies")
        elseif not me and     ally and     enemy then
            out = _everyone("everyone") .. " except " .. _me("self")
        elseif not me and not ally and not enemy then
            out = _field()
        end
    end

    out = rt.settings.action_tooltip.target_prefix .. out
    out = rt.settings.action_tooltip.n_uses_prefix .. "<mono>" .. ternary(self.max_n_uses ~= POSITIVE_INFINITY, tostring(self.max_n_uses), rt.settings.action_tooltip.infinity_uses_label)  .. "</mono>\n" .. out

    return out
end