--- @class bt.EquipmentSlot
bt.EquipmentSlot = meta.new_type("EquipmentSlot", function(equipment)
    meta.assert_isa(equipment, bt.Equipment)

    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "knife"
    local sprite_size_x, sprite_size_y = env.equipment_spritesheet:get_frame_size(sprite_id)
    local out = meta.new(bt.EquipmentSlot, {
        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _attack_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _attack_backdrop = rt.Spacer(),
        _attack_overlay = rt.OverlayLayout(),
        _attack_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _defense_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _defense_backdrop = rt.Spacer(),
        _defense_overlay = rt.OverlayLayout(),
        _defense_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _speed_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _speed_backdrop = rt.Spacer(),
        _speed_overlay = rt.OverlayLayout(),
        _speed_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _hp_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _hp_backdrop = rt.Spacer(),
        _hp_overlay = rt.OverlayLayout(),
        _hp_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _indicator_box = rt.BoxLayout(rt.Orientation.HORIZONTAL),

        _main = rt.BoxLayout(rt.Orientation.VERTICAL)

    }, rt.Drawable, rt.Widget)


    for _, stat in pairs({"attack", "defense", "speed", "hp"}) do
        local backdrop = out["_" .. stat .. "_backdrop"]
        local indicator = out["_" .. stat .. "_indicator"]
        local overlay = out["_" .. stat .. "_overlay"]
        local frame = out["_" .. stat .. "_frame"]

        indicator:set_margin(2 * rt.settings.margin_unit)

        --overlay:set_base_child(backdrop)
        --overlay:push_overlay(indicator)
        --frame:set_child(overlay)
        out._indicator_box:push_back(indicator)

        indicator:set_minimum_size(sprite_size_x, sprite_size_y)
        indicator:set_expand(false)
    end
    out._indicator_box:set_spacing(rt.settings.margin_unit)
    out._indicator_box:set_vertical_alignment(rt.Alignment.END)

    out._sprite_backdrop:set_color(rt.Palette.BASE)
    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)
    out._sprite_frame:set_child(out._sprite_overlay)
    out._sprite_frame:set_expand(false)
    out._sprite_frame:set_minimum_size(sprite_size_x * 4, sprite_size_y * 4)

    --out._indicator_box:set_horizontal_alignment(rt.Alignment.END)
    --out._sprite_frame:set_horizontal_alignment(rt.Alignment.START)
    out._main:push_back(out._sprite_frame)
    out._main:push_back(out._indicator_box)

    return out
end)

--- @brief [internal]
function bt.EquipmentSlot:toplevel()
    return self._main
end

--- @overload rt.Drawable.draw
function bt.EquipmentSlot:draw()
    meta.assert_isa(self, bt.EquipmentSlot)
    self:toplevel():draw()
end

--- @overload rt.Widget.size_allocate
function bt.EquipmentSlot:size_allocate(x, y, width, height)
    meta.assert_isa(self, bt.EquipmentSlot)
    self:toplevel():size_allocate(x, y, width, height)
end

--- @overload rt.Widget.realize
function bt.EquipmentSlot:realize()
    meta.assert_isa(self, bt.EquipmentSlot)
    self:toplevel():realize()
    rt.Widget.realize(self)
end