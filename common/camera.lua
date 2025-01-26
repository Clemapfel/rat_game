rt.settings.camera = {
    position_speed = 1000, -- px per second
    angle_speed = 1000, -- rad per second
    scale_speed = 500, -- 1x per second
    position_inertia_decay_speed = 0.65, -- decreases to 0 per second
    angle_inertia_decay_speed = 0.5, -- decreases to 0 per second
    scale_inertia_decay_speed = 2, -- decreases to 0 per second

    shake_intensity = 1,
    n_shakes_per_second = 75,
    motion_blur = true
}

--- @class rt.Camera
rt.Camera = meta.new_type("Camera", rt.Drawable, rt.Updatable, function(state)
    meta.assert_isa(state, rt.GameState)
    local aabb = rt.AABB(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    local out = meta.new(rt.Camera, {
        _state = state,
        _aabb = aabb,

        _current_x = aabb.x + 0.5 * aabb.width,
        _current_y = aabb.y + 0.5 * aabb.height,
        _target_x = aabb.x + 0.5 * aabb.width,
        _target_y = aabb.y + 0.5 * aabb.height,
        _position_speed = rt.settings.camera.position_speed,
        _position_inertia = 0,
        _position_inertia_speed = rt.settings.camera.position_inertia_decay_speed,

        _offset_path = nil, -- rt.Path
        _offset_path_duration = 0,
        _offset_path_elapsed = 0,
        _offset_x = 0,
        _offset_y = 0,

        _current_angle = 0,
        _target_angle = 0,
        _angle_speed = rt.settings.camera.angle_speed,
        _angle_inertia = 0,
        _angle_inertia_speed = rt.settings.camera.angle_inertia_decay_speed,

        _current_scale = 1,
        _target_scale = 1,
        _scale_speed = rt.settings.camera.scale_speed,
        _scale_inertia = 0,
        _scale_inertia_speed = rt.settings.camera.scale_inertia_decay_speed,

        _elapsed = 0,

        _blur_strength = 0,
        _render_texture_a = nil, -- love.Canvas
        _render_texture_b = nil, -- love.Canvas
        _render_texture_mesh = nil, -- love.Mesh
        _blur_shader_horizontal = love.graphics.newShader("common/camera_blur.glsl", {
            defines = { HORIZONTAL_OR_VERTICAL = 1 }
        }),
        _blur_shader_vertical = love.graphics.newShader("common/camera_blur.glsl", {
            defines = { HORIZONTAL_OR_VERTICAL = 0 }
        }),
    })

    out:set_viewport(rt.aabb_unpack(aabb))
    return out
end)

--- @brief
function rt.Camera:override_position(center_x, center_y)
    self._current_x = center_x
    self._current_y = center_y
    self._target_x = center_x
    self._target_y = center_y
end

--- @brief
function rt.Camera:override_scale(level)
    self._current_scale = level
    self._target_scale = level
end

--- @brief
function rt.Camera:override_angle(angle)
    self._current_angle = angle
    self._target_angle = angle
end

--- @brief
function rt.Camera:set_position(center_x, center_y)
    self._position_inertia = 0
    self._target_x, self._target_y = center_x, center_y
end

--- @brief
function rt.Camera:set_angle(angle)
    self._position_inertia = 0
    self._target_angle = angle
end

--- @brief
function rt.Camera:set_scale(scale)
    self._scale_inertia = 0
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
    self._blur_strength = 0
end

--- @brief
function rt.Camera:reset()
    local x, y, w, h = rt.aabb_unpack(self._aabb)
    self:override_position(x + 0.5 * w, y + 0.5 * h)
    self:override_scale(1)
    self:override_angle(0)
    self:skip()
end

--- @brief
function rt.Camera:set_viewport(x, y, w, h)
    self._aabb = rt.AABB(x, y, w, h)
    local settings = {
        msaa = 0,
        format = rt.TextureFormat.RGB565 -- 16-bit, fully opaque
    }

    self._render_texture_a = love.graphics.newCanvas(w, h, settings)
    self._render_texture_b = love.graphics.newCanvas(w, h, settings)
    self._blur_shader_horizontal:send("texture_size", { self._aabb.width, self._aabb.height })
    self._blur_shader_vertical:send("texture_size", { self._aabb.width, self._aabb.height })

    local vertex_format = {
        {location = 0, name = "VertexPosition", format = "floatvec2"},
        {location = 1, name = "VertexTexCoord", format = "floatvec2"},
    }

    -- use padded mesh that is larger than the screen, such that when the
    -- camera shakes, the texture wrap mode hides the edges of the screen
    local padding = -0.5
    local vertex_data = {
        {      padding * w,       padding * h,      padding,     padding},
        {(1 - padding) * w,       padding * h,  1 - padding,     padding},
        {(1 - padding) * w, (1 - padding) * h,  1 - padding, 1 - padding},
        {      padding * w, (1 - padding) * h,      padding, 1 - padding}
    }
    self._render_texture_mesh = love.graphics.newMesh(vertex_format, vertex_data, rt.MeshDrawMode.TRIANGLE_FAN)
    self._render_texture_mesh:setTexture(self._render_texture_b)

    for texture in range(self._render_texture_a, self._render_texture_b) do
        texture:setWrap(rt.TextureWrapMode.MIRROR)
    end
end

do
    local lg = love.graphics

    --- @brief
    function rt.Camera:bind()
        lg.push()
        lg.origin()

        if self._blur_strength > 0 then
            lg.setCanvas({ self._render_texture_b, stencil = true })
            lg.clear(true, false, false)
        else
            lg.translate(self._offset_x, self._offset_y) -- shake separate, applied to padded mesh to avoid bordering
        end

        lg.translate(self._current_x, self._current_y)
        lg.scale(self._current_scale)
        lg.rotate(self._current_angle)
        lg.translate( -0.5 * self._aabb.width, -0.5 * self._aabb.height)
    end

    -- scene draw here

    --- @brief
    function rt.Camera:unbind()
        if self._blur_strength > 0 then
            lg.origin()
            local a, b = self._render_texture_a, self._render_texture_b
            for i = 1, self._blur_strength do
                lg.setShader(self._blur_shader_horizontal)
                lg.setCanvas(a)
                lg.draw(b)

                lg.setShader(self._blur_shader_vertical)
                lg.setCanvas(b)
                lg.draw(a)
            end

            lg.setCanvas()
            lg.translate(self._offset_x, self._offset_y)
            lg.draw(self._render_texture_mesh)
        end

        lg.pop()
    end
end

--- @brief debug draw
function rt.Camera:draw()
    love.graphics.push()
    love.graphics.reset()
    local radius = 0.5 * self._aabb.height / 4
    do -- draw scale
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

    do -- draw angle
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

    -- draw position
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", self._target_x, self._target_y, 5)
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.circle("fill", self._target_x, self._target_y, 4)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", self._current_x, self._current_y, 5)
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.circle("fill", self._current_x, self._current_y, 4)

    do -- draw offset
        local cx, cy = self._current_x, self._current_y

        love.graphics.setColor(0, 0, 0, 1)
        local r = self:_get_shake_radius()
        local x, y = self._offset_x / r * radius, self._offset_y / r * radius
        love.graphics.setLineWidth(4)
        love.graphics.line(cx, cy, cx + x, cy + y)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(3)
        love.graphics.line(cx, cy, cx + x, cy + y)
    end

    love.graphics.pop()
end

--- @brief
function rt.Camera:_get_shake_radius()
    return 0.01 * math.min(self._aabb.width, self._aabb.height) * rt.settings.camera.shake_intensity
end

--- @override
function rt.Camera:update(delta)
    self._elapsed = self._elapsed + delta

    -- update position
    if self._current_x ~= self._target_x or self._current_y ~= self._target_y then
        local distance_x = self._target_x - self._current_x
        local distance_y = self._target_y - self._current_y

        local step_x = distance_x * self._position_speed * delta * delta
        local step_y = distance_y * self._position_speed * delta * delta

        step_x = step_x * self._position_inertia
        step_y = step_y * self._position_inertia

        self._blur_strength = math.round(rt.magnitude(distance_x, distance_y) / math.min(self._aabb.width, self._aabb.height))

        self._position_inertia = self._position_inertia + delta * self._position_inertia_speed
        if self._position_inertia > 1 then self._position_inertia = 1 end

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

    -- update shake
    if self._offset_path ~= nil then
        self._offset_path_elapsed = self._offset_path_elapsed + delta
        local offset_fraction = self._offset_path_elapsed / self._offset_path_duration
        local previous_x, previous_y = self._offset_x, self._offset_y
        self._offset_x, self._offset_y = self._offset_path:at(offset_fraction)

        self._offset_velocity = rt.distance(previous_x, previous_y, self._offset_x, self._offset_y)
        self._blur_strength = math.max(self._blur_strength, math.ceil(self._offset_velocity / self:_get_shake_radius()) * 3)

        if self._offset_path_elapsed > self._offset_path_duration then
            self._offset_path = nil
            self._offset_path_duration = 0
            self._offset_path_elapsed = 0
            self._blur_strength = 0
        end
    end

    -- update angle
    if self._current_angle ~= self._target_angle then
        local distance = self._target_angle - self._current_angle
        distance = (distance + math.pi) % (2 * math.pi) - math.pi -- always chooses shortest path along the circle

        local step = distance * self._angle_speed * delta * delta
        step = math.min(math.abs(step), self._angle_speed * delta)
        if distance < 0 then step = step * -1 end

        step = step * self._angle_inertia
        self._angle_inertia = self._angle_inertia + delta * self._angle_inertia_speed
        if self._angle_inertia > 1 then self._angle_inertia = 1 end

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
        local step = math.sign(distance) * math.sqrt(math.abs(distance)) * self._scale_speed * delta * delta
        step = math.min(self._scale_speed * delta * delta, step) -- modulate slowdown for asthetic reasons

        step = step * self._scale_inertia
        self._scale_inertia = self._scale_inertia + delta * self._scale_inertia_speed
        if self._scale_inertia > 1 then self._scale_inertia = 1 end

        self._current_scale = self._current_scale + step

        if  (distance > 0 and self._current_scale > self._target_scale) or
            (distance < 0 and self._current_scale < self._target_scale)
        then
            self._current_scale = self._target_scale
        end
    end
end


--- @brief
function rt.Camera:shake(duration, x_radius, y_radius, n_shakes_per_second)
    if x_radius == nil then x_radius = self:_get_shake_radius() end
    if y_radius == nil then y_radius = self:_get_shake_radius() end
    if n_shakes_per_second == nil then
        n_shakes_per_second = rt.settings.camera.n_shakes_per_second
    end
    meta.assert_number(duration, x_radius, y_radius, n_shakes_per_second)

    local step = 0.075 -- noise increment, the smaller the smoother the path
    local vertices = {}
    local seed = rt.random.number(0, 65536 - 1) -- so shake is different every time
    table.insert(vertices, 0)
    table.insert(vertices, 0)
    for i = 1, math.ceil(n_shakes_per_second * duration) do
        table.insert(vertices,  (rt.random.noise(seed, i * step) * 2 - 1) * x_radius)
        table.insert(vertices,  (rt.random.noise(-i * step, seed) * 2 - 1) * y_radius)
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