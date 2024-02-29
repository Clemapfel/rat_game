rt.settings.overworld.camera = {
    collider_radius = 10,
    collider_mass = 50,        -- mass of the camera center physics object
    collider_speed = 2000,      -- magnitude of force impulse in the direction of camera centers target
    max_velocity = 500          -- maximum camera velocity during panning
}

--- @class ow.CameraScript
ow.CameraScript = meta.new_type("CameraScript", function(positions, zoom, rotation)

    -- use splines to interpolate between 1-dimensional values by setting second dimension to 0

    -- xy component is center
    local vertices = {}
    for i = 1, #positions, 2 do
        table.insert(vertices, positions[i+0])
        table.insert(vertices, positions[i+1])
    end

    -- x, y component is scale
    local scales = {self._scale, self._scale}
    for i = 1, #zoom, 1 do
        table.insert(scales, zoom[i])
        table.insert(scales, zoom[i])
    end

    -- x component is rotation
    local rotations = {0, 0}
    for i = 1, #rotations do
        table.insert(rotations, rotation[i]:as_radians())
        table.insert(rotations, 0)
    end

    local out = meta.new(ow.CameraScript, {
        _position = rt.Spline(vertices),
        _rotation = rt.Spline(rotations),
        _zoom = rt.Spline(scales)
    })
end)

--- @class ow.Camera
--- @signal reached (self) -> nil emitted when camera reaches a position specified by `move_to`
ow.Camera = meta.new_type("Camera", rt.SignalEmitter, rt.Animation, function()
    local out = meta.new(ow.Camera, {
        _scale = 1,
        _angle = rt.radians(0),

        _target_x = 0,
        _target_y = 0,

        _world = rt.PhysicsWorld(0, 0),
        _collider = {}, -- rt.CircleCollider
        _is_moving = false
    })

    out._collider = rt.CircleCollider(out._world, rt.ColliderType.DYNAMIC, 0, 0, rt.settings.overworld.camera.collider_radius)
    out._collider:set_mass(rt.settings.overworld.camera.collider_mass)
    out:_set_target_positions(0, 0)
    out:set_is_animated(true)

    out:signal_add("reached")
    return out
end)

rt.SplineType = rt.BezierCurve

--- @brief [internal]
function ow.Camera:_set_target_positions(x, y)
    self._target_x = x
    self._target_y = y
end

--- @brief
function ow.Camera:update(delta)
    local current_x, current_y = self._collider:get_centroid()
    local angle = rt.angle(self._target_x - current_x, self._target_y - current_y)
    local magnitude = rt.settings.overworld.camera.collider_speed

    -- distance between camera and diagonal
    function distance(x1, y1, x2, y2, x0, y0)
        local num = math.abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)
        local den = math.sqrt((y2 - y1)^2 + (x2 - x1)^2)
        return num / den
    end

    local distance = rt.magnitude(self._target_x - current_x, self._target_y - current_y)
    local vx, vy = rt.translate_point_by_angle(0, 0, magnitude, angle)
    self._collider:apply_linear_impulse(vx, vy)

    -- increase friction as object gets closer to target, to avoid overshooting
    local damping = magnitude / (4 * distance)
    self._collider:set_linear_damping(damping)

    if distance < 1 and self._is_moving then
        self._is_moving = false
        self:signal_emit("reached")
    end

    self._world:update(delta)

    -- clamp velocity to set maximum
    local current_velocity = rt.magnitude(self._collider:get_linear_velocity())
    local max_velocity = rt.settings.overworld.camera.max_velocity
    if current_velocity > max_velocity then
        self._collider:set_linear_velocity(rt.translate_point_by_angle(0, 0, max_velocity, angle))
    end
end

--- @brief
function ow.Camera:reset()
    self:reset_position()
    self:reset_scale()
    self:reset_rotation()
end

--- @brief initiate for the camera to move to center a certain point
function ow.Camera:move_to(x, y)
    self:_set_target_positions(x, y)
    self._is_moving = true
end

--- @brief teleport the camera such that immediately shows point
function ow.Camera:center_on(x, y)
    self._target_x = x
    self._target_y = y
    self._collider:set_position(x, y)
    self._collider:set_linear_velocity(0, 0)
end

--- @brief
function ow.Camera:reset_position()
    self:_set_target_positions(
        love.graphics.getWidth() / 2,
        love.graphics.getHeight() / 2
    )
end

--- @brief
function ow.Camera:set_rotation(angle)
    self._angle = angle
end

--- @brief
function ow.Camera:rotate(offset)
    self._angle = self._angle + offset
end

--- @brief
function ow.Camera:reset_rotation()
    self._angle = 0
end

--- @brief
function ow.Camera:set_scale(scale)
    self._scale = scale
end

--- @brief
function ow.Camera:reset_scale()
    self._scale = 1
end

--- @brief
function ow.Camera:zoom_in(amount)
    self._scale = clamp(self._scale + amount, 0.01)
end

--- @brief
function ow.Camera:zoom_out(amount)
    self._scale = clamp(self._scale - amount, 0.01)
end

--- @brief
function ow.Camera:bind()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.push()
    love.graphics.origin()

    local translate_x, translate_y = 0.5 * w, 0.5 * h
    local x, y = self._collider:get_centroid()

    translate_x = math.floor(translate_x)
    translate_y = math.floor(translate_y)
    x = math.floor(x)
    y = math.floor(y)

    rt.graphics.translate(translate_x, translate_y)
    rt.graphics.rotate(self._angle:as_radians())
    rt.graphics.scale(self._scale, self._scale)
    rt.graphics.translate(-1 * translate_x, -1 * translate_y)

    rt.graphics.translate(-1 * x + 0.5 * w, -1 * y + 0.5 * h)
end

--- @brief
function ow.Camera:unbind()
    love.graphics.pop()
end

--- @TODO
function ow.Camera:draw()
    love.graphics.push()
    --love.graphics.reset()
    self._collider:draw()
    local x, y = self._collider:get_centroid()
    love.graphics.line(x, y, self._target_x, self._target_y)
    love.graphics.circle("fill", self._target_x, self._target_y, 5)
    love.graphics.pop()
end