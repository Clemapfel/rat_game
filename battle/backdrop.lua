rt.settings.battle.backdrop = {
    frame_thickness = 2
}

--- @class bt.Backdrop
bt.Backdrop = meta.new_type("Backdrop", rt.Widget, function()
    return meta.new(bt.Backdrop, {
        _backdrop = rt.Frame(), -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer
    })
end)

--- @override
function bt.Backdrop:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._backdrop_backing = rt.Spacer()
    self._backdrop = rt.Frame()
    self._backdrop:set_child(self._backdrop_backing)
    self._backdrop:set_thickness(rt.settings.battle.backdrop.frame_thickness)
    self._backdrop:set_color(rt.Palette.FOREGROUND)

    self._backdrop_backing:realize()
    self._backdrop:realize()
    self._backdrop:set_opacity(1)
end

--- @override
function bt.Backdrop:get_top_level_widget()
    return self._backdrop
end