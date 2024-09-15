--- @class rt.PhysicsBasedAnimation
rt.PhysicsBasedAnimation = meta.new_type("PhysicsBasedAnimation", function(world, position_x, position_y, damping_to_distance_coefficient)
    meta.assert_isa(world, b2.World)
    meta.assert_number(position_x, position_y)

    local body = b2.Body(world, b2.BodyType.DYNAMIC, position_x, position_y)
    local shape = b2.CircleShape(body, b2.Circle(1))
    shape:set_density(1)
    shape:set_collision_group(b2.CollisionGroup.NONE)

    if damping_to_distance_coefficient == nil then damping_to_distance_coefficient = 1 end
    return meta.new(rt.PhysicsBasedAnimation, {
        _position_body = body,
        _position_shape = shape,
        _damping_factor = damping_to_distance_coefficient,
        _current_position_x = position_x,
        _current_position_y = position_y,
        _target_position_x = position_x,
        _target_position_y = position_y,
    })
end)

--- @brief
function rt.PhysicsBasedAnimation:get_position()
    local x, y = self._position_body:get_centroid()
    return math.round(x), math.round(y)
end

--- @brief
function rt.PhysicsBasedAnimation:set_position(position_x, position_y)
    self._target_position_x, self._target_position_y = position_x, position_y
end

--- @brief
function rt.PhysicsBasedAnimation:step()
    local current_x, current_y = self._current_position_x, self._current_position_y
    local target_x, target_y = self._target_position_x, self._target_position_y
    local distance = rt.distance(current_x, current_y, target_x, target_y)
    local angle = rt.angle(target_x - current_x, target_y - current_y)
    local vx, vy = rt.translate_point_by_angle(0, 0, distance, angle)
    self._position_body:set_linear_damping((1000 * self._damping_factor) / distance)
    self._position_body:apply_linear_impulse(vx, vy)
    self._current_position_x, self._current_position_y = self._position_body:get_centroid()
end

--- @brief
function rt.PhysicsBasedAnimation:destroy()
    self._position_body:destroy()
end