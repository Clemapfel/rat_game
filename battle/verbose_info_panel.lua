rt.settings.battle.verbose_info_backdrop = {
    base_color = rt.Palette.GRAY_6,
    frame_color = rt.Palette.GRAY_5,
    frame_thickness = 10,
    corner_radius = 5
}

--- @class bt.VerboseInfoBackdrop
bt.VerboseInfoBackdrop = meta.new_type("VerboseInfoBackdrop", rt.Widget, function()
    return meta.new(bt.VerboseInfoBackdrop, {
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
    })
end)

--- @override
function bt.VerboseInfoBackdrop:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.verbose_info_backdrop.base_color)
    self._frame:set_color(rt.settings.battle.verbose_info_backdrop.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    local frame_thickness = rt.settings.battle.verbose_info_backdrop.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    self._frame:set_line_width(frame_thickness)
    self._frame_outline:set_line_width(frame_outline_thickness)

    for shape in range(self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.verbose_info_backdrop.corner_radius)
    end
end

--- @override
function bt.VerboseInfoBackdrop:size_allocate(x, y, width, height)
    self._backdrop:resize(x, y, width, height)

    local frame_thickness = rt.settings.battle.verbose_info_backdrop.frame_thickness
    local frame_aabb = rt.AABB(
    x - 0.5 * frame_thickness,
    y - 0.5 * frame_thickness,
    width + frame_thickness,
    height + frame_thickness
    )
    self._frame:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
    self._frame_outline:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
end

--- @override
function bt.VerboseInfoBackdrop:draw()
    if self._is_realized then
        self._frame_outline:draw()
        self._frame:draw()
        self._backdrop:draw()

    end
end