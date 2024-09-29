--- @class rt.SmoothedMotion2D
rt.SmoothedMotion2D = meta.new_type("SmoothedMotion2D", function(position_x, position_y, damping_to_distance_coefficient)
    if position_y == nil then position_y = 0 end
    meta.assert_number(position_x, position_y)

    local body = b2.Body(rt.SmoothedMotion2D._world, b2.BodyType.KINEMATIC, position_x, position_y, true  )
      local shape = b2.CircleShape(body, b2.Circle(1))
    shape:set_collision_group(b2.CollisionGroup.NONE)
    --body:set_mass(1)

    if damping_to_distance_coefficient == nil then damping_to_distance_coefficient = 1 end
    return meta.new(rt.SmoothedMotion2D, {
        _position_body = body,
        _position_shape = shape,
        _velocity_factor = 1,
        _damping_factor = damping_to_distance_coefficient,
        _current_position_x = position_x,
        _current_position_y = position_y,
        _target_position_x = position_x,
        _target_position_y = position_y,
    })
end, {
    _world = b2.World(0, 0)
})

--- @brief
function rt.SmoothedMotion2D:get_position()
    local x, y = self._position_body:get_centroid()
    assert(x ~= nil and y ~= nil)
    return x, y
end

--- @brief
function rt.SmoothedMotion2D:set_target_position(x, y)
    if y == nil then y = 0 end
    self._target_position_x, self._target_position_y = x, y
end

--- @brief
function rt.SmoothedMotion2D:update(_)
    self._current_position_x, self._current_position_y = self._position_body:get_centroid()

    local current_x, current_y = self._current_position_x, self._current_position_y
    local target_x, target_y = self._target_position_x, self._target_position_y

    local distance = rt.magnitude(target_x - current_x, target_y - current_y)
    local angle = rt.angle(target_x - current_x, target_y - current_y)
    local vx, vy = rt.translate_point_by_angle(0, 0, distance, angle)

    self._position_body:set_linear_velocity(vx, vy)
    --[[

    local distance = rt.magnitude(target_x - current_x, target_y - current_y)
    local angle = rt.angle(target_x - current_x, target_y - current_y)
    local magnitude = 0.1
    local vx, vy = rt.translate_point_by_angle(0, 0, magnitude * distance, angle)
    self._position_body:apply_force(vx, vy)

    local damping = 1 / (magnitude * distance)
    self._position_body:set_linear_damping(damping)
    ]]--
end

--- @brief
function rt.SmoothedMotion2D:set_position(x, y)
    if y == nil then y = 0 end
    self._position_body:set_linear_velocity(0, 0)
    self._position_body:set_angular_velocity(0)
    self._position_body:set_centroid(x, y)
end