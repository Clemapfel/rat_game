--- @class mn.ShakeIntensityWidget
mn.ShakeIntensityWidget = meta.new_type("ShakeIntensityWidget", rt.Widget, rt.Animation, function()
    return meta.new(mn.ShakeIntensityWidget, {
        _shape = rt.Rectangle(0, 0, 1, 1),
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
    if self._is_realized == true then return end
    self._is_realized = true
end

--- @brief
function mn.ShakeIntensityWidget:_initialize_path()
    local min_x, max_x = -1, 1
    local min_y, max_y = -1, 1

    local points = {}
    for i = 1, math.ceil(self._duration) * 10 do
        table.insert(points, rt.random.number(min_x, max_x))
        table.insert(points, rt.random.number(min_y, max_y))
    end

    self._path = rt.Spline(points, true)
    self._last_motion_intensity = rt.settings.motion_intensity
end

--- @override
function mn.ShakeIntensityWidget:size_allocate(x, y, width, height)
    local w, h = 0.5 * width, 0.5 * height
    self._shape:resize(x + 0.5 * width - 0.5 * w, y + 0.5 * height - 0.5 * h, w, h)
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
    rt.graphics.translate(-point_x, -point_y)
end