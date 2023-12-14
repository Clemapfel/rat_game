rt.settings.status_tooltip = {
    duration_prefix = "<b>Duration:</b> ",
    infinity_duration_label = "―――",
    effect_prefix = "<b><u>Effect</u>:</b> "
}

--- @class bt.StatusTooltip
bt.StatusTooltip = meta.new_type("StatusTooltip", function(status)

    local out = meta.new(bt.StatusTooltip, {
        _status_ailment = status,
        _sprite = status:create_sprite(),
        _tooltip = {} -- bt.BattleTooltip
    }, rt.Widget, rt.Drawable)

    out._tooltip = bt.BattleTooltip(
        out._status_ailment.name,
        out:_format_duration(),
        rt.settings.status_tooltip.effect_prefix .. out._status_ailment.verbose_description,
        out._status_ailment.flavor_text,
        out._sprite
    )

    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.StatusTooltip:get_top_level_widget()
    return self._tooltip:get_top_level_widget()
end

--- @bief [internal]
function bt.StatusTooltip:_format_duration()
    local duration = self._status_ailment.max_duration
    return rt.settings.status_tooltip.duration_prefix .. ternary(duration ~= POSITIVE_INFINITY, tostring(duration), rt.settings.status_tooltip.infinity_duration_label)
end