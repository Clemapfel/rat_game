rt.settings.equipment_slot = {
    indicator_min_size = 64
}

--- @class bt.EquipmentSlot
bt.EquipmentSlot = meta.new_type("EquipmentSlot", rt.Widget, function(equipment)

    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "none"
    if not meta.is_nil(equipment) then
        sprite_id = equipment.sprite_id
    end

    local function value_to_direction(value)
        if value > 0 then
            return rt.Direction.UP
        elseif value < 0 then
            return rt.Direction.DOWN
        else
            return rt.Direction.NONE
        end
    end

    local attack_direction = value_to_direction(0)
    local defense_direction = value_to_direction(0)
    local speed_direction = value_to_direction(0)
    local hp_direction = value_to_direction(0)

    if not meta.is_nil(equipment) then
        attack_direction = value_to_direction(equipment.attack_modifier)
        defense_direction = value_to_direction(equipment.defense_modifier)
        speed_direction = value_to_direction(equipment.speed_modifier)
        hp_direction = value_to_direction(equipment.hp_modifier)
    end

    local out = meta.new(bt.EquipmentSlot, {
        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(rt.FrameType.RECTANGULAR),
        _sprite_inlay = rt.Spacer(),

        _hp_indicator = rt.DirectionIndicator(hp_direction),
        _hp_backdrop = rt.Spacer(),
        _hp_overlay = rt.OverlayLayout(),
        _hp_frame = rt.Frame(rt.FrameType.RECTANGULAR),

        _attack_indicator = rt.DirectionIndicator(attack_direction),
        _attack_backdrop = rt.Spacer(),
        _attack_overlay = rt.OverlayLayout(),
        _attack_frame = rt.Frame(rt.FrameType.RECTANGULAR),

        _defense_indicator = rt.DirectionIndicator(defense_direction),
        _defense_backdrop = rt.Spacer(),
        _defense_overlay = rt.OverlayLayout(),
        _defense_frame = rt.Frame(rt.FrameType.RECTANGULAR),

        _speed_indicator = rt.DirectionIndicator(speed_direction),
        _speed_backdrop = rt.Spacer(),
        _speed_overlay = rt.OverlayLayout(),
        _speed_frame = rt.Frame(rt.FrameType.RECTANGULAR),

        _indicator_box = rt.BoxLayout(rt.Orientation.VERTICAL),
        _indicator_box_frame = rt.Frame(rt.FrameType.RECTANGULAR)
    })

    for stat in range("hp", "attack", "defense", "speed") do
        local backdrop = out["_" .. stat .. "_backdrop"]
        local indicator = out["_" .. stat .. "_indicator"]
        local overlay = out["_" .. stat .. "_overlay"]
        local frame = out["_" .. stat .. "_frame"]

        indicator:set_margin(5)
        overlay:set_base_child(backdrop)
        overlay:push_overlay(indicator)
        backdrop:set_color(rt.Palette.BASE)

        out._indicator_box:push_back(overlay)
    end
    out._indicator_box_frame:set_child(out._indicator_box)

    out._hp_indicator:set_color(rt.Palette.HP)
    out._attack_indicator:set_color(rt.Palette.ATTACK)
    out._defense_indicator:set_color(rt.Palette.DEFENSE)
    out._speed_indicator:set_color(rt.Palette.SPEED)

    out._sprite_backdrop:set_color(rt.Palette.BASE)
    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_overlay:push_overlay(out._sprite_inlay)
    out._sprite_overlay:push_overlay(out._sprite)
    out._sprite_frame:set_child(out._sprite_overlay)

    out._indicator_box_frame:set_thickness(1)
    --out._indicator_box_frame:set_color(rt.Palette.BLACK)
    out._sprite_frame:set_thickness(1)
    --out._sprite_frame:set_color(rt.Palette.BLACK)
    out._sprite_inlay:set_corner_radius(2 * rt.settings.margin_unit)
    out._sprite_inlay:set_color(rt.color_darken(rt.Palette.BASE, 0.05))
    out._sprite_inlay:set_margin(rt.settings.margin_unit * 1.5)
    out._sprite_inlay:set_show_outline(false, false, false, false)
    return out
end)

--- @overload rt.Drawable.draw
function bt.EquipmentSlot:draw()
    self._sprite_frame:draw()
    self._indicator_box_frame:draw()
end

--- @overload rt.Widget.size_allocate
function bt.EquipmentSlot:size_allocate(x, y, width, height)

    local indicator_w = select(1, self._sprite:get_resolution())
    local sprite_size = indicator_w * 4

    x = x + 0.5 * (width - sprite_size - indicator_w)
    y = y + 0.5 * (height - sprite_size)

    self._sprite_frame:fit_into(rt.AABB(x, y, sprite_size, sprite_size))
    self._indicator_box_frame:fit_into(rt.AABB(x + sprite_size, y, indicator_w * 1.15, sprite_size))
end

--- @overload rt.Widget.measure
function bt.EquipmentSlot:measure()
    local sprite_w, sprite_h = self._sprite_frame:measure()
    local indicator_w, indicator_h = self._indicator_box_frame:measure()
    return sprite_w + indicator_w, sprite_h
end

--- @overload rt.Widget.realize
function bt.EquipmentSlot:realize()

    self._sprite_frame:realize()
    self._indicator_box_frame:realize()
    rt.Widget.realize(self)
end