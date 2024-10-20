--- @class mn.MSAAIntensityWidget
mn.MSAAIntensityWidget = meta.new_type("MSAAIntensityWidget", rt.Widget, rt.Updatable, function()
    return meta.new(mn.MSAAIntensityWidget, {
        _shape = rt.Line(0, 0, 1),
        _shape_radius_x = 1,
        _shape_radius_y = 1,
        _shape_center_x = 0,
        _shape_center_y = 0,
        _shape_background = rt.Rectangle(0, 0, 1, 1),
        _elapsed = 0,
        _duration = 15, -- in seconds, on full rotation
    })
end)

--- @override
function mn.MSAAIntensityWidget:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._shape:set_color(rt.Palette.TRUE_BLACK)
    self._shape:set_is_outline(true)
    self._shape:set_line_width(2 * rt.settings.margin_unit)
    self._shape:set_line_join(rt.LineJoin.MITER)
    self._shape_background:set_color(rt.Palette.TRUE_WHITE)
    self._shape_background:set_corner_radius(rt.settings.frame.corner_radius)
end

--- @override
function mn.MSAAIntensityWidget:size_allocate(x, y, width, height)
    local w, h = 0.8 * width, 0.8 * height
    self._shape_background:resize(x + 0.5 * width - 0.5 * w, y + 0.5 * height - 0.5 * h, w, h)

    local rx, ry = 0.3 * w, 0.3 * h
    self._shape_radius_x = rx
    self._shape_radius_y = ry
    self._shape_center_x = x + 0.5 * width
    self._shape_center_y =  y + 0.5 * height
    self:update(0)
end

--- @override
function mn.MSAAIntensityWidget:update(delta)
    self._elapsed = math.fmod(self._elapsed + delta, self._duration)

    local n_vertices = 5
    local points = {}
    local angle_step = 2 * math.pi / n_vertices

    local center_x, center_y = self._shape_center_x, self._shape_center_y
    local radius_x, radius_y = self._shape_radius_x, self._shape_radius_y

    local angle_offset = self._elapsed / self._duration * 2 * math.pi
    for i = 0, n_vertices - 1 do
        local angle = i * angle_step + angle_offset
        local x = center_x + radius_x * math.cos(angle)
        local y = center_y + radius_y * math.sin(angle)
        table.insert(points, x)
        table.insert(points, y)
    end

    table.insert(points, points[1])
    table.insert(points, points[2])

    self._shape:resize(points)
end

--- @override
function mn.MSAAIntensityWidget:draw()
    self._shape_background:draw()
    self._shape:draw()
end