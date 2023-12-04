rt.settings.battle_tooltip = {
    name_prefix = "<b>",
    name_suffix = "</b>",
    flavor_text_prefix = "<color=GREY_2><i>(",
    flavor_text_suffix = ")</color></i>",
    sprite_size = 64
}

--- @class bt.BattleTooltip
bt.BattleTooltip = meta.new_type("BattleTooltip", function(name, status, description, flavor_text)

    local out = meta.new(bt.BattleTooltip, {
        _entity = entity,
        _name_label = rt.Label(rt.settings.battle_tooltip.name_prefix .. name .. rt.settings.battle_tooltip.name_suffix),
        _stat_label = rt.Label(status),
        _description_label = rt.Label(description),
        _flavor_text_label = rt.Label(rt.settings.battle_tooltip.flavor_text_prefix .. flavor_text .. rt.settings.battle_tooltip.flavor_text_suffix),

        _sprite = rt.Spacer(),
        _sprite_aspect = rt.AspectLayout(1),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(),

        _name_and_sprite_box = rt.BoxLayout(rt.Orientation.HORIZONTAL),
        _main = rt.BoxLayout(rt.Orientation.VERTICAL)
    }, rt.Widget, rt.Drawable)


    out._name_label:set_expand_horizontally(true)

    out._sprite_backdrop:set_color(rt.Palette.GREY_5)
    out._sprite:set_minimum_size(rt.settings.battle_tooltip.sprite_size, rt.settings.battle_tooltip.sprite_size)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)
    out._sprite_frame:set_child(out._sprite_overlay)
    out._sprite_frame:set_color(rt.Palette.GREY_3)
    out._sprite_frame:set_thickness(2)

    out._name_and_sprite_box:push_back(out._sprite_frame)
    out._name_and_sprite_box:push_back(out._name_label)

    out._main:push_back(out._name_and_sprite_box)
    out._main:push_back(out._stat_label)
    out._main:push_back(out._description_label)
    --out._main:push_back(out._flavor_text_label)

    out._sprite_frame:set_expand(false)

    for _, element in pairs({out._name_and_sprite_box, out._stat_label, out._description_label, out._flavor_text_label}) do
        element:set_alignment(rt.Alignment.START)
        element:set_expand_vertically(false)
    end

    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._flavor_text_label:set_horizontal_alignment(rt.Alignment.CENTER)

    out._name_label:set_margin_left(rt.settings.margin_unit)
    out._main:set_spacing(rt.settings.margin_unit)

    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.BattleTooltip:get_top_level_widget()
    return self._main
end

--- @brief
function bt.BattleTooltip:set_name(name)
    self._name_label:set_text(rt.settings.battle_tooltip.name_prefix .. name .. rt.settings.battle_tooltip.name_suffix)
end

--- @brief
function bt.BattleTooltip:set_description(text)
    self._description_label:set_text(text)
end

--- @brief
function bt.BattleTooltip:set_stat_text(text)
    self._stat_label:set_text(text)
end

--- @brief
function bt.BattleTooltip:set_flavor_text(text)
    self._flavor_text_label:set_text(rt.settings.battle_tooltip.flavor_text_prefix .. text .. rt.settings.battle_tooltip.flavor_text_suffix)
end

--- @brief
function bt.BattleTooltip:set_sprite(widget)
    self._sprite_aspect:set_child(widget)
end