--- @class rt.PhysicsBasedAnimation
rt.PhysicsBasedAnimation = meta.new_type("PhysicsBasedAnimation", function()
    return meta.new(rt.PhysicsBasedAnimation, {
        _world = b2.World(0, 0),
    })
end)

--- @class rt.PhysicsBasedAnimation.ID
rt.PhysicsBasedAnimation.ID = meta.new_type("PhysicsBasedAnimationID")

--- @brief
--- @return rt.PhysicsBasedAnimation.ID
function rt.PhysicsBasedAnimation:add(position_x, position_y, weight)
    local body = b2.Body(self._world, b2.BodyType.DYNAMIC, position_x, position_y)
    local radius = 1
    local shape = b2.CircleShape(body, b2.Circle(1))
    if weight == 0 then weight = 1 end
    shape:set_density(weight / (math.pi * radius ^ 2))
    return meta.new(rt.PhysicsBasedAnimation.ID, {
        body = body,
        shape = shape,
        target_position_x = position_x,
        target_position_y = position_y
    })
end

--- @brief
function rt.PhysicsBasedAnimation:set_position(id, position_x, position_y)
    meta.assert_isa(id, rt.PhysicsBasedAnimation.ID)
    id.target_position_x = position_x
    id.target_position_y = position_y
end

--- @brief
function rt.PhysicsBasedAnimation:get_position(id)
    return id.:get_position()
end

--- @brief
function rt.PhysicsBasedAnimation:update(delta)
    self._world:update(delta)
end
