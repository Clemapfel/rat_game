rt.settings.selection_indicator = {
    thickness = 5,
    outline_width = 10,
    corner_radius = 5,
    alpha = 1
}

--- @class
rt.SelectionIndicator = meta.new_type("SelectionIndicator", rt.Widget,  rt.Animation, function()
    return meta.new(rt.SelectionIndicator, {
        _frame = rt.Rectangle(0, 0, 1, 1),
        _outline = rt.Rectangle(0, 0, 1, 1),
    })
end)

--- @override
function rt.SelectionIndicator:resize(other_widget)
    local x, y = other_widget:get_position()
    local w, h = other_widget:measure()

    self._frame = rt.Rectangle(x, y, w, h)
    self._outline = rt.Rectangle(x, y, w, h)

    self._frame:set_color(rt.Palette.SELECTION)
    self._outline:set_color(rt.Palette.BACKGROUND)

    local line_width = rt.settings.selection_indicator.thickness
    self._frame:set_line_width(line_width)
    self._outline:set_line_width(line_width + 3)

    local corner_radius = rt.settings.selection_indicator.corner_radius
    for which in range(self._frame, self._outline) do
        which:set_corner_radius(corner_radius)
        which:set_is_outline(true)
    end
end

--- @override
function rt.SelectionIndicator:update(delta)
    -- noop for now
end

--- @override
function rt.SelectionIndicator:draw()
    self._outline:draw()
    self._frame:draw()
end
