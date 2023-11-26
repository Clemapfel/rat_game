rt.settings.equipment_tooltip = {
        effect_prefix = "<b><u>Effect</u></b>: "
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
        _name_label = rt.Label("<b>" .. equipment.name .. "</b>"),
        _effect_label = rt.Label(rt.settings.equipment_tooltip.effect_prefix .. equipment.effect_text .. ""),
        _flavor_text_label = rt.Label(ternary(#equipment.flavor_text == 0, "", "<color=GREY_2>(" .. equipment.flavor_text .. ")</color>")),
        _flavor_text_hrule = rt.Spacer(),

        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(),

        _stat_label = {}, -- rt.Label

        _name_and_sprite_box = rt.BoxLayout(rt.Orientation.HORIZONTAL),
        _effect_box = rt.BoxLayout(rt.Orientation.VERTICAL),

        _vbox = rt.BoxLayout(rt.Orientation.VERTICAL),
    }, rt.Widget, rt.Drawable)


    -- offset each label with spaces so the right-most digit aligns
    local get_n_digits = function(x)
        if x < 0 then x = math.abs(x) end
        return math.floor(math.log(x, 10)) + 1 + ternary(x < 0, 1, 0)
    end

    local n_digits = 0
    for _, modifier in pairs({equipment.attack_modifier, equipment.defense_modifier, equipment.speed, equipment.hp}) do
        n_digits = math.max(n_digits, get_n_digits(modifier))
    end

    local modifier_to_label = function(modifier)
    meta.assert_number(modifier)

        local out = ""
        for i = 1, n_digits - get_n_digits(modifier) do
            out = out .. " "
        end

        if modifier == 0 then
            out = out .. "±"
        elseif modifier > 0 then
            out = out .. "+"
        end

        return out .. tostring(modifier)
    end

    local stat_label_text = ""
    stat_label_text = stat_label_text
    .. ternary(equipment.attack_modifier ~= 0, "<color=ATTACK>ATK: " .. modifier_to_label(equipment.attack_modifier) .. "</color>\n", "")
    .. ternary(equipment.defense_modifier ~= 0, "<color=DEFENSE>DEF: " .. modifier_to_label(equipment.defense_modifier) .. "</color>\n", "")
    .. ternary(equipment.speed_modifier ~= 0, "<color=SPEED>SPD: " .. modifier_to_label(equipment.speed_modifier) .. "</color>\n", "")
    .. ternary(equipment.hp_modifier ~= 0, "<color=HP>HP : " .. modifier_to_label(equipment.hp_modifier) .. "</color>\n", "")

    out._stat_label = rt.Label(stat_label_text, rt.settings.font.default_mono)
    out._stat_label:set_margin_top(0.5 * rt.settings.margin_unit)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)

    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)
    out._sprite_frame:set_child(out._sprite_overlay)
    out._sprite_frame:set_color(rt.Palette.GREY_3)
    out._sprite_frame:set_thickness(2)

    out._sprite_backdrop:set_color(rt.Palette.GREY_5)

    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._name_label:set_margin_horizontal(rt.settings.margin_unit)
    out._name_label:set_expand_horizontally(true)

    out._name_and_sprite_box:push_back(out._sprite_frame)
    out._name_and_sprite_box:push_back(out._name_label)
    out._name_and_sprite_box:set_alignment(rt.Alignment.START)
    out._sprite_frame:set_expand_horizontally(false)
    out._name_label:set_expand_horizontally(true)
    out._name_and_sprite_box:set_expand_vertically(false)
    out._name_and_sprite_box:set_expand_horizontally(true)

    out._sprite_frame:set_expand(false)
    out._sprite_frame:set_minimum_size(sprite_size_x * 2, sprite_size_y * 2)

    for _, label in pairs({out._name_label, out._effect_label, out._stat_label}) do
    label:set_horizontal_alignment(rt.Alignment.START)
    label:set_margin_left(rt.settings.margin_unit)
    end
    out._effect_label:set_margin_vertical(rt.settings.margin_unit)

    out._effect_label:set_alignment(rt.Alignment.START)
    out._effect_label:set_margin(rt.settings.margin_unit)
    out._effect_label:set_expand_vertically(false)

    out._flavor_text_label:set_margin(rt.settings.margin_unit)
    out._flavor_text_label:set_expand_vertically(false)
    out._flavor_text_label:set_margin_bottom(rt.settings.margin_unit)

    out._flavor_text_hrule:set_color(rt.Palette.FOREGROUND)
    out._flavor_text_hrule:set_expand_vertically(false)
    out._flavor_text_hrule:set_minimum_size(0, 3)

    out._vbox:push_back(out._name_and_sprite_box)

    if #stat_label_text > 0 then
    out._vbox:push_back(out._stat_label)
    end

    out._vbox:push_back(out._effect_label)

    return out
    end)

--- @brief [internal]
function bt.EquipmentTooltip:get_top_level_widget()
    return self._vbox
end