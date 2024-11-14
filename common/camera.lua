rt.settings.camera = {
    shake_intensity = 1, -- in [0, 1]
    n_shakes_per_second = 100
}

--- @class rt.Camera
rt.Camera = meta.new_type("Camera", rt.Updatable, function()
    local aabb = rt.AABB(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    return meta.new(rt.Camera, {
        _aabb = aabb,

        _current_x = aabb.x + 0.5 * aabb.width,
        _current_y = aabb.y + 0.5 * aabb.height,
        _target_x = aabb.x + 0.5 * aabb.width,
        _target_y = aabb.y + 0.5 * aabb.height,

        _position_path = nil, -- rt.Path

        _offset_path = nil,
        _offset_path_duration = 0,
        _offset_path_elapsed = 0,
        _offset_x = 0,
        _offset_y = 0,

        _current_angle = 0,
        _target_angle = 0,

        _current_zoom = 1,
        _target_zoom = 1,

        _is_bound = false,
        _elapsed = 0
    })
end)

--- @override
function rt.Camera:update(delta)
    self._elapsed = self._elapsed + delta
    if self._offset_path ~= nil then
        self._offset_path_elapsed = self._offset_path_elapsed + delta
        self._offset_x, self._offset_y = self._offset_path:at(self._offset_path_elapsed / self._offset_path_duration)
        if self._offset_path_elapsed > self._offset_path_duration then
            self._offset_path = nil
            self._offset_path_duration = 0
            self._offset_path_elapsed = 0
        end
    end
end

--- @brief
function rt.Camera:skip()
    self._current_x = self._target_x
    self._current_y = self._target_y
    self._offset_x = 0
    self._offset_y = 0
    self._current_zoom = self._target_zoom
    self._current_angle = self._target_angle

    self._offset_path_duration = 0
    self._offset_path_elapsed = 0
    self._offset_path = nil
end

--- @brief
function rt.Camera:bind()
    love.graphics.push()

    rt.graphics.origin()

    love.graphics.translate(self._offset_x, self._offset_y)
    love.graphics.translate(self._current_x, self._current_y)
    love.graphics.scale(self._current_zoom)
    love.graphics.rotate(self._current_angle)
    love.graphics.translate( -0.5 * self._aabb.width, -0.5 * self._aabb.height)
end

--- @brief
function rt.Camera:unbind()
    love.graphics.pop()
end

--- @brief
function rt.Camera:set_viewport(x, y, w, h)
    self._aabb = rt.AABB(x, y, w, h)
end

--- @brief
function rt.Camera:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(self._target_x, self._target_y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setPointSize(4)
    love.graphics.points(self._target_x, self._target_y)
end

--- @brief override position
function rt.Camera:set_position(center_x, center_y)
    self._current_x = center_x
    self._current_y = center_y
    self._path = nil
end

--- @brief override zoom
function rt.Camera:set_zoom(level)
    self._current_zoom = level
    self._target_zoom = level
end

--- @brief override angle
function rt.Camera:set_angle(angle)
    self._current_angle = angle
    self._target_angle = angle
end

--- @brief move to point with interpolation
function rt.Camera:move_to(center_x, center_y)

end

--- @brief
function rt.Camera:shake(duration, x_radius, y_radius, n_shakes_per_second)
    self._offset_path_duration = self._offset_path_duration + duration

    local shake_intensity = rt.settings.camera.shake_intensity
    x_radius, y_radius = x_radius * shake_intensity, y_radius * shake_intensity

    if n_shakes_per_second == nil then
        n_shakes_per_second = rt.settings.camera.n_shakes_per_second
    end

    local vertices = {}
    table.insert(vertices, 0)
    table.insert(vertices, 0)
    for i = 1, math.floor(n_shakes_per_second * duration) do
        local angle = rt.random.number(-math.pi, math.pi)
        table.insert(vertices, math.cos(angle) * x_radius)
        table.insert(vertices, math.sin(angle) * y_radius)
    end
    table.insert(vertices, 0)
    table.insert(vertices, 0)

    if self._offset_path ~= nil then
        for point in values(self._offset_path:list_points()) do
            table.insert(vertices, 1, point[2])
            table.insert(vertices, 1, point[1])

        end
    end

    self._offset_path = rt.Path(vertices)
    self._offset_path_duration = self._offset_path_duration + duration
end

--- @brief
function rt.Camera:zoom(level)

end

--- @brief
function rt.Camera:set_rotation(angle)

end