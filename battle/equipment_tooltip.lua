--- @class bt.EquipmentTooltip
bt.EquipmentTooltip = meta.new_type("EquipmentTooltip", function(equipment)
    meta.assert_isa(equipment, bt.Equipment)
    local out = meta.new(bt.EquipmentTooltip, {
        _backdrop = rt.Spacer(),
        _frame = rt.Frame()
    }, rt.Drawable, rt.Widget)

    out._frame:set_child(out._backdrop)
    return out
end)

--- @overload rt.Drawable.draw
function bt.EquipmentTooltip:draw()
    meta.assert_isa(self, bt.EquipmentTooltip)
    self._frame:draw()
end

--- @overload rt.Widget.size_allocate
function bt.EquipmentTooltip:size_allocate(x, y, width, height)
    meta.assert_isa(self, bt.EquipmentTooltip)
    self._frame:size_allocate(x, y, width, height)
end

--- @overload rt.Widget.realize
function bt.EquipmentTooltip:realize()
    self._frame:realize()
end