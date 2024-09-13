--- @class b2.Joint
b2.Joint = meta.new_type("PhysicsJoint", function()
    rt.error("In b2.Joint(): trying to initialize a joint directly, use `DistanceJoint`, `MouseJoint` instead")
    return nil
end)

--- @brief
function b2.Joint:destroy()
    box2d.b2DestroyJoint(self._native)
end

--- @brief
function b2.DistanceJoint(
    world,
    body_a, body_b,
    length,
    a_anchor_x, a_anchor_y,
    b_anchor_x, b_anchor_y,
    collide_connected,
    is_spring, hertz, damping
)
    local def = box2d.b2DefaultDistanceJointDef()
    def.bodyIdA = body_a._native
    def.bodyIdB = body_b._native

    if length <= 0 then
        rt.warning("In b2.DistanceJoint: length <= 0")
    end

    if length == nil then length = 1 / 1000 end

    def.length = length

    if a_anchor_x == nil then a_anchor_x = 0 end
    if a_anchor_y == nil then a_anchor_y = 0 end
    if b_anchor_x == nil then b_anchor_x = 0 end
    if b_anchor_y == nil then b_anchor_y = 0 end

    def.localAnchorA = b2.Vec2(a_anchor_x, a_anchor_y)
    def.localAnchorB = b2.Vec2(b_anchor_x, b_anchor_y)

    if collide_connected == nil then collide_connected = true end
    def.collideConnected = collide_connected

    if is_spring == nil then is_spring = false end
    if hertz == nil then hertz = 1.0 end
    if damping == nil then damping = 0 end

    if is_spring == true then
        def.enableSpring = true
        def.hertz = hertz
        def.dampingRatio = damping
    end

    return meta.new(b2.Joint, {
        _native = box2d.b2CreateDistanceJoint(world._native, def)
    })
end

--- @class b2.MouseJoint
function b2.MouseJoint(
    world,
    body_a, body_b,
    position_x, position_y,
    collide_connected,
    hertz, damping, max_force
)
    local def = box2d.b2DefaultMouseJointDef()
    def.bodyIdA = body_a._native
    def.bodyIdB = body_b._native
    def.target = b2.Vec2(position_x, position_y)

    if collide_connected == nil then collide_connected = true end
    def.collideConnected = collide_connected

    if hertz == nil then hertz = 1.0 end
    if damping == nil then damping = 0 end
    if max_force == nil then max_force = POSITIVE_INFINITY end -- TODO
    def.hertz = hertz
    def.dampingRatio = damping
    def.maxForce = max_force

    return meta.new(b2.Joint, {
        _native = box2d.b2CreateMouseJoint(world._native, def)
    })
end

--- @class b2.JointType
b2.JointType = meta.new_enum({
    DISTANCE_JOINT = box2d.b2_distanceJoint,
    MOTOR_JOINT = box2d.b2_motorJoint,
    MOUSE_JOINT = box2d.b2_mouseJoint,
    PRISMATIC_JOINT = box2d.b2_prismaticJoint,
    REVOLUTE_JOINT = box2d.b2_revoluteJoint,
    WELD_JOINT = box2d.b2_weldJoint,
    WHEEL_JOINT = box2d.b2_wheelJoint
})

--- @brief
function b2.Joint:get_type()
    return box2d.b2Joint_GetType(self._native)
end

--- @brief
function b2.Joint:get_bodies()
    local body_a = meta.new(b2.Body, {
        _native = box2d.b2Joint_GetBodyA(self._native)
    })

    local body_b = meta.new(b2.Body, {
        _native = box2d.b2Joint_GetBodyB(self._native)
    })

    return body_a, body_b
end

--- @brief
--- @return Number, Number, Number, Number a_anchor_x, a_anchor_y, b_anchor_x, b_anchor_y
function b2.Joint:get_local_anchors()
    local a_anchor = box2d.b2Joint_GetLocalAnchorA(self._native)
    local b_anchor = box2d.b2Joint_GetLocalAnchorB(self._native)
    return a_anchor.x, a_anchor.y, b_anchor.x, b_anchor.y
end

--- @brief
function b2.Joint:set_collide_connected(b)
    box2d.b2Joint_SetCollideConnected(self._native, b)
end

--- @brief
function b2.Joint:get_collide_connected()
    return box2d.b2Joint_GetCollideConnected(self._native)
end

--- @brief
function b2.Joint:wake_bodies()
    box2d.b2Joint_WakeBodies(self._native)
end

--- @brief
function b2.Joint:get_constraint_force()
    local force = box2d.b2Joint_GetConstraintForce(self._native)
    return force.x, force.y
end

--- @brief
function b2.Joint:get_constraint_torque()
    return box2d.b2Joint_GetConstraintTorque(self._native)
end

--- @brief
function b2.Joint:draw()
    local local_a = box2d.b2Joint_GetLocalAnchorA(self._native)
    local local_b = box2d.b2Joint_GetLocalAnchorB(self._native)
    local body_a = box2d.b2Joint_GetBodyA(self._native)
    local body_b = box2d.b2Joint_GetBodyB(self._native)

    local a = box2d.b2Body_GetWorldPoint(body_a, local_a)
    local b = box2d.b2Body_GetWorldPoint(body_b, local_b)

    love.graphics.line(a.x, a.y, b.x, b.y)
end