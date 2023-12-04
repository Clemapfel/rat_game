rt.settings.entity_tooltip.description_prefix = "<color=GREY_2><i>("
rt.settings.entity_tooltip.description_suffix = ")</color></i>"
rt.settings.entity_tooltip.no_status_label = "none"

--- @class bt.EntityTooltip
bt.EntityTooltip = meta.new_type("EntityTooltip", function(entity)

    local out = meta.new(bt.EntityTooltip, {
        _entity = entity,
        _name_label = rt.Label("<b>" .. entity.name .. "</b>"),
        _stat_Label = {}, -- rt.Label
        _status_ailment_label = {},
        _description_label = rt.Label(rt.settings.entity_tooltip.description_prefix .. entity.description .. rt.settings.entity_tooltip.description_suffix),

        _sprite = rt.Spacer(),
        _sprite_aspect = rt.AspectLayout(1),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(),
        _name_and_sprite_box = rt.BoxLayout(rt.Orientation.HORIZONTAL),

        _main = rt.BoxLayout(rt.Orientation.VERTICAL)
    }, rt.Widget, rt.Drawable)

    out._stat_label = rt.Label(out:_format_stat_label())
    out._status_ailment_label = rt.Label(out:_format_status_ailment_label())

    for _, label in pairs({out._name_label, out._stat_label, out._status_ailment_label, out._description_label}) do
        label:set_horizontal_alignment(rt.Alignment.START)
        label:set_margin_left(rt.settings.margin_unit)
        label:set_expand_vertically(false)
    end


    out._sprite_overlay:set_base_child(out._sprite_backdrop)

    out._sprite:set_minimum_size(32 * 2, 32 * 2)

    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)
    out._sprite_frame:set_child(out._sprite_overlay)
    out._sprite_frame:set_color(rt.Palette.GREY_3)
    out._sprite_frame:set_thickness(2)

    out._sprite_backdrop:set_color(rt.Palette.GREY_5)
    out._name_and_sprite_box:push_back(out._sprite_frame)
    out._name_and_sprite_box:push_back(out._name_label)
    out._name_and_sprite_box:set_alignment(rt.Alignment.START)
    out._sprite_frame:set_expand_horizontally(false)
    out._name_label:set_expand_horizontally(true)
    out._name_and_sprite_box:set_expand_vertically(false)
    out._name_and_sprite_box:set_expand_horizontally(true)

    out._main:push_back(out._name_and_sprite_box)
    out._main:push_back(out._stat_label)
    out._main:push_back(out._status_ailment_label)
    out._main:push_back(out._description_label)
    return out
end)

bt.EntityTooltip._censor_attack = true
bt.EntityTooltip._censor_defense = false
bt.EntityTooltip._censor_speed = true
bt.EntityTooltip._censor_hp = true

--- @overload rt.Widget.get_top_level_widget
function bt.EntityTooltip:get_top_level_widget()
    return self._main
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

    if self._entity.status_ailments:size() == 0 then
        return "<b>Status Effects:</b> " .. rt.settings.entity_tooltip.no_status_label
    end

    local out = "<b>Status:<b>\n"
    for _, status in pairs(self._entity.status_ailments) do
        out = out .. "\t" .. status.name .. "\n"
    end
    return out
end