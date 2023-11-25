rt.settings.equipment_tooltip = {
        effect_prefix = "Effect: "
}

--- @class bt.EquipmentTooltip
bt.EquipmentTooltip = meta.new_type("EquipmentTooltip", function(equipment)
    meta.assert_isa(equipment, bt.Equipment)

    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "knife"
    local sprite_size_x, sprite_size_y = env.equipment_spritesheet:get_frame_size(sprite_id)
    local out = meta.new(bt.EquipmentTooltip, {
        _backdrop = rt.Spacer(),
        _frame = rt.Frame(),

        _name_label = rt.Label("<b>" .. equipment.name .. "</b>"),
        _effect_label = rt.Label(rt.settings.equipment_tooltip.effect_prefix .. equipment.effect_text),
        _flavor_text_label = rt.Label(ternary(#equipment.flavor_text == 0, "", "(" .. equipment.flavor_text .. ")")),

        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(),

        _name_and_sprite_box = rt.BoxLayout(rt.Orientation.HORIZONTAL)
    }, rt.Widget)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)

    out._sprite_aspect:set_child(out._sprite)
    out._sprite_frame:set_child(out._sprite_aspect)
    out._sprite_overlay:push_overlay(out._sprite_frame)

    out._sprite_backdrop:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._sprite_frame:set_color(rt.Palette.YELLOW)

    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._name_label:set_margin_horizontal(rt.settings.margin_unit)
    out._name_label:set_expand_horizontally(true)

    out._name_and_sprite_box:push_back(out._sprite_frame)
    out._name_and_sprite_box:push_back(out._name_label)
    out._name_and_sprite_box:set_alignment(rt.Alignment.START)
    out._sprite_frame:set_expand_horizontally(false)
    out._name_label:set_expand_horizontally(true)

    out._sprite_frame:set_expand(false)
    out._sprite_frame:set_minimum_size(sprite_size_x * 3, sprite_size_y * 3)

    return out
end)

--- @brief [internal]
function bt.EquipmentTooltip:get_top_level_widget()
    return self._name_and_sprite_box
end
