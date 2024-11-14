rt.settings.camera = {
    shake_intensity = 1, -- in [0, 1]
    position_speed = 1000, -- px per second
    angle_speed = 1000, -- rad per second
    scale_speed = 500, -- 1x per second
    n_shakes_per_second = 100
}

--- @class rt.Camera
rt.Camera = meta.new_type("Camera", rt.Drawable, rt.Updatable, function()
    local aabb = rt.AABB(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    return meta.new(rt.Camera, {
        _aabb = aabb,

        _current_x = aabb.x + 0.5 * aabb.width,
        _current_y = aabb.y + 0.5 * aabb.height,
        _target_x = aabb.x + 0.5 * aabb.width,
        _target_y = aabb.y + 0.5 * aabb.height,
        _position_speed = rt.settings.camera.position_speed,

        _position_path = nil, -- rt.Path

        _offset_path = nil,
        _offset_path_duration = 0,
        _offset_path_elapsed = 0,
        _offset_x = 0,
        _offset_y = 0,

        _current_angle = 0,
        _target_angle = 0,
        _angle_speed = rt.settings.camera.angle_speed,

        _current_scale = 1,
        _target_scale = 1,
        _scale_speed = rt.settings.camera.scale_speed,

        _is_bound = false,
        _elapsed = 0,

        _render_texture = rt.RenderTexture(1, 1)
    })
end)

--- @brief override position
function rt.Camera:override_position(center_x, center_y)
    self._current_x = center_x
    self._current_y = center_y
    self._target_x = center_x
    self._target_y = center_y
    self._path = nil
end

--- @brief override scale
function rt.Camera:override_scale(level)
    self._current_scale = level
    self._target_scale = level
end

--- @brief override angle
function rt.Camera:override_angle(angle)
    self._current_angle = angle
    self._target_angle = angle
end

--- @brief move to point with interpolation
function rt.Camera:set_position(center_x, center_y)
    self._target_x, self._target_y = center_x, center_y
end

--- @brief
function rt.Camera:set_angle(angle)
    self._target_angle = angle
end

--- @brief
function rt.Camera:set_scale(scale)
    self._target_scale = scale
end

--- @brief
function rt.Camera:skip()
    self:override_position(self._target_x, self._target_y)
    self:override_scale(self._target_scale)
    self:override_angle(self._target_angle)

    self._offset_x, self._offset_y = 0, 0
    self._offset_path = nil
    self._offset_path_elapsed = 0
    self._offset_path_duration = 0
end

--- @override
function rt.Camera:update(delta)
    self._elapsed = self._elapsed + delta

    -- update shake
    if self._offset_path ~= nil then
        self._offset_path_elapsed = self._offset_path_elapsed + delta
        self._offset_x, self._offset_y = self._offset_path:at(self._offset_path_elapsed / self._offset_path_duration)
        if self._offset_path_elapsed > self._offset_path_duration then
            self._offset_path = nil
            self._offset_path_duration = 0
            self._offset_path_elapsed = 0
        end
    end

    -- update position
    if self._current_x ~= self._target_x or self._current_y ~= self._target_y then
        local distance_x = self._target_x - self._current_x
        local distance_y = self._target_y - self._current_y

        local step_x = distance_x * self._position_speed * delta * delta
        local step_y = distance_y * self._position_speed * delta * delta

        local max_step = self._position_speed * delta
        if step_x > max_step then step_x = max_step end
        if step_y > max_step then step_y = max_step end

        self._current_x = self._current_x + step_x
        self._current_y = self._current_y + step_y

        if  (distance_x > 0 and self._current_x > self._target_x) or
            (distance_x < 0 and self._current_x < self._target_x)
        then
            self._current_x = self._target_x
        end

        if  (distance_y > 0 and self._current_y > self._target_y) or
            (distance_y < 0 and self._current_y < self._target_y)
        then
            self._current_y = self._target_y
        end
    end

    -- update angle
    if self._current_angle ~= self._target_angle then
        -- always chooses shortest path along the circle
        local distance = self._target_angle - self._current_angle
        distance = (distance + math.pi) % (2 * math.pi) - math.pi

        local step = distance * self._angle_speed * delta * delta
        step = math.min(math.abs(step), self._angle_speed * delta)
        if distance < 0 then step = step * -1 end

        self._current_angle = self._current_angle + step

        if  (distance > 0 and self._current_angle > self._current_angle) or
            (distance < 0 and self._current_angle < self._current_angle)
        then
            self._current_angle = self._current_angle
        end
    end
    
    -- update scale
    if self._current_scale ~= self._target_scale then
        local distance = self._target_scale - self._current_scale
        local step = distance * self._scale_speed * delta * delta
        step = math.min(self._scale_speed * delta * delta, step)

        self._current_scale = self._current_scale + step

        if  (distance > 0 and self._current_scale > self._target_scale) or
            (distance < 0 and self._current_scale < self._target_scale)
        then
            self._current_scale = self._target_scale
        end
    end
end

--- @brief
function rt.Camera:bind()
    love.graphics.push()

    rt.graphics.origin()

    love.graphics.translate(self._offset_x, self._offset_y)
    love.graphics.translate(self._current_x, self._current_y)
    love.graphics.scale(self._current_scale)
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
    local current_w, current_h = self._render_texture:get_size()
    if current_w ~= w or current_h ~= h then
        self._render_texture = rt.RenderTexture(w, h, state:get_msaa_quality(), rt.TextureFormat.NORMAL) -- TODO
    end
end

--- @brief
function rt.Camera:draw()
    love.graphics.push()
    love.graphics.origin()
    local radius = 0.5 * self._aabb.height / 4

    do
        local current_r = self._current_scale * radius
        local target_r = self._target_scale * radius
        local cx, cy = self._current_x, self._current_y

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", cx, cy, current_r)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", cx, cy, current_r)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", cx, cy, target_r)
        love.graphics.setColor(0, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", cx, cy, target_r)
    end

    do
        local cx, cy = self._current_x, self._current_y
        local current_x, current_y = rt.translate_point_by_angle(cx, cy, radius * 2, self._current_angle)
        local target_x, target_y = rt.translate_point_by_angle(cx, cy, radius * 2, self._target_angle)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.line(cx, cy, current_x, current_y)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(cx, cy, current_x, current_y)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.line(cx, cy, target_x, target_y)
        love.graphics.setColor(0, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(cx, cy, target_x, target_y)
    end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(self._target_x, self._target_y)
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.setPointSize(4)
    love.graphics.points(self._target_x, self._target_y)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(self._current_x, self._current_y)
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.setPointSize(4)
    love.graphics.points(self._current_x, self._current_y)

    love.graphics.pop()
end


--- @brief
function rt.Camera:shake(duration, x_radius, y_radius, n_shakes_per_second)
    if x_radius == nil then x_radius = 0 end
    if y_radius == nil then y_radius = 0 end
    if n_shakes_per_second == nil then
        n_shakes_per_second = rt.settings.camera.n_shakes_per_second
    end
    meta.assert_number(duration, x_radius, y_radius, n_shakes_per_second)

    local shake_intensity = rt.settings.camera.shake_intensity
    x_radius, y_radius = x_radius * shake_intensity, y_radius * shake_intensity

    local vertices = {}
    table.insert(vertices, 0)
    table.insert(vertices, 0)
    for i = 1, math.floor(n_shakes_per_second * duration) do
        table.insert(vertices, rt.random.number(-x_radius, x_radius))
        table.insert(vertices, rt.random.number(-y_radius, y_radius))
    end
    table.insert(vertices, 0)
    table.insert(vertices, 0)

    -- append if already shaking
    if self._offset_path ~= nil then
        for point in values(self._offset_path:list_points()) do
            table.insert(vertices, 1, point[2])
            table.insert(vertices, 1, point[1])
        end
    end

    self._offset_path = rt.Path(vertices)
    self._offset_path_duration = self._offset_path_duration + duration
end