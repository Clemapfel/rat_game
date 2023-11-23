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

        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(),

        _overlay = rt.OverlayLayout()
    }, rt.Drawable, rt.Widget)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)

    out._sprite_aspect:set_child(out._sprite)
    out._sprite_frame:set_child(out._sprite_aspect)
    out._sprite_overlay:push_overlay(out._sprite_frame)

    out._sprite_backdrop:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._sprite_frame:set_color(rt.Palette.YELLOW)

    out._overlay:set_base_child(out._backdrop)
    out._overlay:push_overlay(out._sprite_frame)
    out._sprite_overlay:set_alignment(rt.Alignment.START)

    out._frame:set_child(out._overlay)
    return out
end)

--- @brief [internal]
function bt.EquipmentTooltip:toplevel()
    return self._frame
end

--- @overload rt.Drawable.draw
function bt.EquipmentTooltip:draw()
    meta.assert_isa(self, bt.EquipmentTooltip)
    self:toplevel():draw()
end

--- @overload rt.Widget.size_allocate
function bt.EquipmentTooltip:size_allocate(x, y, width, height)
    meta.assert_isa(self, bt.EquipmentTooltip)
    self:toplevel():size_allocate(x, y, width, height)
end

--- @overload rt.Widget.realize
function bt.EquipmentTooltip:realize()
    meta.assert_isa(self, bt.EquipmentTooltip)
    self:toplevel():realize()
    rt.Widget.realize(self)
end