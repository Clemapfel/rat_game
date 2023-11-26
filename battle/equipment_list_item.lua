--- @class bt.EquipmentListItem
bt.EquipmentListItem = meta.new_type("EquipmentListItem", function(equipment)
    meta.assert_isa(equipment, bt.Equipment)
    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "knife"
    local sprite_size_x, sprite_size_y = env.equipment_spritesheet:get_frame_size(sprite_id)
    sprite_size_x = sprite_size_x * 1
    sprite_size_y = sprite_size_y * 1

    local out = meta.new(bt.EquipmentListItem, {
        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),

        _name_label = rt.Label(equipment.name),

        _name_spacer = rt.Spacer(),

        _attack_indicator = rt.DirectionIndicator(),
        _defense_indicator = rt.DirectionIndicator(),
        _speed_indicator = rt.DirectionIndicator(),
        _hp_indicator = rt.DirectionIndicator(),
        _indicator_hbox = rt.BoxLayout(rt.Orientation.HORIZONTAL),

        _count_spacer = rt.Spacer(),
        _count_label = rt.Label("0" .. tostring(1), rt.settings.font.default_mono),

        _hbox = rt.BoxLayout(rt.Orientation.HORIZONTAL),

        _tooltip = bt.EquipmentTooltip(equipment),
        _tooltip_layout = rt.TooltipLayout()
    }, rt.Widget, rt.Drawable)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)

    out._tooltip_layout:set_child(out._hbox)
    out._tooltip_layout:set_tooltip(out._tooltip)

    for _, spacer in pairs({out._name_spacer, out._count_spacer}) do
        spacer:set_expand_horizontally(false)
        spacer:set_expand_vertically(true)
        spacer:set_minimum_size(3, 0)
        spacer:set_color(rt.Palette.FOREGROUND)
    end

    out._sprite:set_minimum_size(sprite_size_x * 2, sprite_size_y * 2)
    out._sprite_overlay:set_expand(false)
    out._name_label:set_expand(true)

    for _, indicator in pairs({out._attack_indicator, out._defense_indicator, out._speed_indicator, out._hp_indicator}) do
        out._indicator_hbox:push_back(indicator)
        indicator:set_minimum_size(sprite_size_x, sprite_size_y)
        indicator:set_expand(false)
    end
    out._indicator_hbox:set_margin_horizontal(rt.settings.margin_unit)
    out._indicator_hbox:set_spacing(rt.settings.margin_unit)

    out._hbox:push_back(out._sprite_overlay)
    out._hbox:push_back(out._name_label)
    out._hbox:push_back(out._name_spacer)
    out._hbox:push_back(out._indicator_hbox)
    out._hbox:push_back(out._count_spacer)
    out._hbox:push_back(out._count_label)

    out._indicator_hbox:set_expand_horizontally(false)
    out._count_label:set_expand_horizontally(false)
    out._count_label:set_margin_horizontal(rt.settings.margin_unit)

    out._hbox:set_expand_vertically(false)

    return out
end)

--- @brief [internal]
function bt.EquipmentListItem:get_top_level_widget()
    return self._tooltip_layout
end