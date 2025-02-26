--- @class mn.ShakeIntensityWidget
mn.ShakeIntensityWidget = meta.new_type("ShakeIntensityWidget", rt.Widget, rt.Updatable, function()
    return meta.new(mn.ShakeIntensityWidget, {
        _shape = rt.Rectangle(0, 0, 1, 1),
        _shape_outline = rt.Rectangle(0, 0, 1, 1),
        _last_motion_intensity = rt.settings.motion_intensity,
        _path = nil, -- rt.Spline
        _shape_width = 1,
        _shape_height = 1,
        _elapsed = 0,
        _duration = 10
    })
end)

--- @override
function mn.ShakeIntensityWidget:realize()
    if self:already_realized() then return end

    self._shape:set_color(rt.Palette.FOREGROUND)
    self._shape_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    self._shape_outline:set_is_outline(true)
    self._shape_outline:set_line_width(3)

    for shape in range(self._shape, self._shape_outline) do
        shape:set_corner_radius(rt.settings.frame.corner_radius)
    end
end

--- @brief
function mn.ShakeIntensityWidget:_initialize_path()
    local points = {0, 0}

    local intensity = clamp(rt.settings.motion_intensity, 0.01)
    if intensity == 0 then
        for i = 1, 2 * 6 do
            table.insert(points, 0)
        end
    else
        for i = 1, math.ceil(self._duration) * 10 do
            local angle = rt.random.number(0, 1) * 2 * math.pi
            local magnitude = 0.1 * intensity
            local x, y = rt.translate_point_by_angle(0, 0, magnitude, angle)
            table.insert(points, x)
            table.insert(points, y)
            table.insert(points, 0)
            table.insert(points, 0)
        end
    end

    self._path = rt.Spline(points, true)
    self._last_motion_intensity = rt.settings.motion_intensity
    self._elapsed = 0
end

--- @override
function mn.ShakeIntensityWidget:size_allocate(x, y, width, height)
    local w, h = 0.5 * width, 0.5 * height
    for shape in range(self._shape, self._shape_outline) do
        shape:resize(x + 0.5 * width - 0.5 * w, y + 0.5 * height - 0.5 * h, w, h)
    end
    self._shape_width = w
    self._shape_height = h

    self:_initialize_path()
end

--- @override
function mn.ShakeIntensityWidget:update(delta)
    self._elapsed = math.fmod(self._elapsed + delta, self._duration)
    if rt.settings.motion_intensity ~= self._last_motion_intensity then
        self:_initialize_path()
    end
end

--- @override
function mn.ShakeIntensityWidget:draw()
    if self._path == nil then return end

    local x_magnitude = self._bounds.width * 0.5 - self._shape_width * 0.5
    local y_magnitude = self._bounds.height * 0.5 - self._shape_height * 0.5
    local point_x, point_y = self._path:at(self._elapsed / self._duration)
    point_x = point_x * x_magnitude
    point_y = point_y * y_magnitude

    rt.graphics.translate(point_x, point_y)
    self._shape:draw()
    self._shape_outline:draw()
    rt.graphics.translate(-point_x, -point_y)
end

