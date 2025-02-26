--- @class mn.DeadzoneVisualizationWidget
mn.DeadzoneVisualizationWidget = meta.new_type("DeadzoneVisualizationWidget", rt.Widget, rt.Updatable, function()
    return meta.new(mn.DeadzoneVisualizationWidget, {
        _inner_shape = rt.Circle(0, 0, 1),
        _outer_shape = rt.Circle(0, 0, 1),
        _last_deadzone = rt.InputControllerState.deadzone
    })
end)

--- @override
function mn.DeadzoneVisualizationWidget:realize()
    if self:already_realized() then return end
    self._inner_shape:set_color(rt.Palette.FOREGROUND)
    self._outer_shape:set_color(rt.Palette.FOREGROUND_OUTLINE)
end

--- @override
function mn.DeadzoneVisualizationWidget:size_allocate(x, y, width, height)
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local deadzone = self._last_deadzone
    local outer_r = (math.min(width, height) - 4 * rt.settings.margin_unit) / 2
    self._inner_shape:resize(center_x, center_y, deadzone * outer_r)
    self._outer_shape:resize(center_x, center_y, outer_r)
end

--- @override
function mn.DeadzoneVisualizationWidget:draw()
    self._outer_shape:draw()
    self._inner_shape:draw()
end

--- @override
function mn.DeadzoneVisualizationWidget:update(delta)
    if rt.InputControllerState.deadzone ~= self._last_deadzone then
        self._last_deadzone = rt.InputControllerState.deadzone
        self:reformat()
    end
end