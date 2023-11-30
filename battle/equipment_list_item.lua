--- @class bt.EquipmentListItem
bt.EquipmentListItem = meta.new_type("EquipmentListItem", function(equipment)
    meta.assert_isa(equipment, bt.Equipment)
    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "default"
    local sprite_size_x, sprite_size_y = env.equipment_spritesheet:get_frame_size(sprite_id)
    sprite_size_x = sprite_size_x * 1
    sprite_size_y = sprite_size_y * 1

    local out = meta.new(bt.EquipmentListItem, {
        _equipment = equipment,
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

    out:set_count(1) -- TODO

    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)

    for _, spacer in pairs({out._sprite_spacer, out._name_spacer, out._count_spacer}) do
        spacer:set_expand_horizontally(false)
        spacer:set_expand_vertically(true)
        spacer:set_minimum_size(3, 0)
        spacer:set_color(rt.Palette.FOREGROUND)
        spacer:set_margin_horizontal(rt.settings.margin_unit)
    end

    out._sprite:set_minimum_size(sprite_size_x * 2, sprite_size_y * 2)
    out._sprite_overlay:set_margin_right(rt.settings.margin_unit)
    out._sprite_overlay:set_expand(false)
    out._name_label:set_expand_horizontally(true)
    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._name_label:set_margin_left(rt.settings.margin_unit)

    for _, indicator in pairs({out._attack_indicator, out._defense_indicator, out._speed_indicator, out._hp_indicator}) do
        out._indicator_hbox:push_back(indicator)
        indicator:set_minimum_size(sprite_size_x, sprite_size_y)
        indicator:set_expand(false)
    end
    out._indicator_hbox:set_spacing(rt.settings.margin_unit)

    out._hbox:push_back(out._sprite_overlay)
    out._hbox:push_back(out._name_label)
    out._hbox:push_back(out._name_spacer)
    out._hbox:push_back(out._indicator_hbox)
    out._hbox:push_back(out._count_spacer)
    --out._hbox:push_back(out._count_label)

    out._indicator_hbox:set_expand_horizontally(false)
    out._count_label:set_expand_horizontally(false)
    out._count_label:set_horizontal_alignment(rt.Alignment.START)
    out._count_label:set_margin_right(2 * rt.settings.margin_unit)

    out._hbox:set_expand_vertically(false)

    out._tooltip_layout:set_child(out._hbox)
    out._tooltip_layout:set_tooltip(out._tooltip)

    out:update_indicators()

    return out
end)

--- @brief [internal]
function bt.EquipmentListItem:get_top_level_widget()
    return self._tooltip_layout
end

--- @brief
function bt.EquipmentListItem:update_indicators(entity)
    -- TODO
    meta.assert_isa(self, bt.EquipmentListItem)

    self._attack_indicator:set_color(rt.Palette.ATTACK)
    self._defense_indicator:set_color(rt.Palette.DEFENSE)
    self._speed_indicator:set_color(rt.Palette.SPEED)
    self._hp_indicator:set_color(rt.Palette.HP)

    local update_direction = function(to_set, value)
        if value > 0 then
            to_set:set_direction(rt.Direction.UP)
        elseif value == 0 then
            to_set:set_direction(rt.Direction.NONE)
        else
            to_set:set_direction(rt.Direction.DOWN)
        end
    end

    for _, which in pairs({"attack", "defense", "speed", "hp"}) do
        update_direction(self["_" .. which .. "_indicator"], self._equipment[which .. "_modifier"])
    end
end

--- @brief
function bt.EquipmentListItem:set_count(n)
    meta.assert_isa(self, bt.EquipmentListItem)
    meta.assert_number(n)
    assert(n > 0)
    self._name_label:set_text(self._equipment.name .. " (" .. tostring(n) .. ") ")
end