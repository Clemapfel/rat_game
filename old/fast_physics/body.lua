--- @class Body
b2.Body = setmetatable({}, {
    __call = function(_, world, type, position_x, position_y)
        return b2.Body:new(world, type, position_x, position_y)
    end
})

--- @class b2.BodyType
b2.BodyType = {
    STATIC = box2d.b2_staticBody,
    KINEMATIC = box2d.b2_kinematicBody,
    DYNAMIC = box2d.b2_dynamicBody
}

--- @brief
function b2.Body:new(world, type, position_x, position_y)
    local def = box2d.b2DefaultBodyDef()
    def.type = type
    def.position = ffi.typeof("b2Vec2")(position_x, position_y)

    --[[
    local body_id = ffi.gc(
        box2d.b2CreateBody(world._native, def),
        box2d.b2DestroyBody
    )
    ]]--

    local body_id = box2d.b2CreateBody(world._native, def)
    return b2.Body:new_from_id(body_id)
end

--- @brief
function b2.Body:new_from_id(id)
    return setmetatable({
        _native = id
    }, {
        __index = b2.Body
    })
end

--- @brief
function b2.Body:new_from_id(id)
    return setmetatable({
        _native = id
    }, {
        __index = b2.Body,
        __newindex = function(self, key, value)
            self._native[key] = value
        end
    })
end

--- @brief
function b2.Body:get_n_shapes()
    return box2d.b2Body_GetShapeCount(self._native)
end

--- @brief
--- @return Table<b2.Shape>
function b2.Body:get_shapes()
    local n = box2d.b2Body_GetShapeCount(self._native)
    local shapes = ffi.new("b2ShapeId*[" .. n .. "]")
    local _ = box2d.b2Body_GetShapes(self._native, shapes, n)
    local out = {}
    for i = 1, n do
        table.insert(out, b2.Shape:new_from_id(out))
    end
    return out
end

--- @brief
function b2.Body:get_type()
    return box2d.b2Body_GetType(self._native)
end

--- @brief
function b2.Body:set_type(type)
    box2d.b2Body_SetType(self._native, type)
end

--- @brief
function b2.Body:get_world_point(local_x, local_y)
    local out = box2d.b2Body_GetWorldPoint(self._native, ffi.typeof("b2Vec2")(local_x, local_y))
    return out.x, out.y
end

--- @brief
function b2.Body:get_world_points(local_x, local_y, ...)
    local points = {local_x, local_y, ...}
    local out = {}
    for i = 1, #points, 2 do
        local vec2 = box2d.b2Body_GetWorldPoint(self._native, ffi.typeof("b2Vec2")(points[i], points[i+1]))
        table.insert(out, vec2.x)
        table.insert(out, vec2.y)
    end
    return table.unpack(out)
end

--- @brief
function b2.Body:get_local_point(local_x, local_y)
    local out = box2d.b2Body_GetLocalPoint(self._native, ffi.typeof("b2Vec2")(local_x, local_y))
    return out.x, out.y
end

--- @brief
function b2.Body:get_local_points(local_x, local_y, ...)
    local points = {local_x, local_y, ...}
    local out = {}
    for i = 1, #points, 2 do
        local vec2 = box2d.b2Body_GetLocalPoint(self._native, ffi.typeof("b2Vec2")(points[i], points[i+1]))
        table.insert(out, vec2.x)
        table.insert(out, vec2.y)
    end
    return table.unpack(out)
end

--- @brief
function b2.Body:set_centroid(point_x, point_y)
    local current = box2d.b2Body_GetTransform(self._native)
    if point_x ~= nil then current.p.x = point_x end
    if point_y ~= nil then current.p.y = point_y end
    box2d.b2Body_SetTransform(self._native, current)
end

--- @brief
function b2.Body:get_centroid(local_offset_x, local_offset_y)
    if local_offset_x == nil then local_offset_x = 0 end
    if local_offset_y == nil then local_offset_y = 0 end
    local out = box2d.b2Body_GetWorldPoint(self._native, ffi.typeof("b2Vec2")(local_offset_x, local_offset_y))
    return out.x, out.y
end

--- @brief
function b2.Body:set_angle(angle_rad)
    local transform = box2d.b2Body_GetTransform(self._native)
    transform.q.x = math.cos(angle_rad)
    transform.q.y = math.sin(angle_rad)
    box2d.b2Body_SetTransform(transform)
end

--- @brief
function b2.Body:get_angle()
    local transform = box2d.b2Body_GetTransform(self._native)
    return math.atan(transform.q.y, transform.q.x)
end

--- @brief
function b2.Body:set_is_fixed_rotation(b)
    box2d.b2Body_SetFixedRotation(self._native, b)
end

--- @brief
function b2.Body:get_is_fixed_rotation()
    return box2d.b2Body_IsFixedRotation(self._native)
end

--- @brief
function b2.Body:set_linear_velocity(x, y)
    box2d.b2Body_SetLinearVelocity(self._native, ffi.typeof("b2Vec2")(x, y))
end

--- @brief
function b2.Body:get_linear_velocity()
    local vec2 = box2d.b2Body_GetLinearVelocity(self._native)
    return vec2.x, vec2.y
end

--- @brief
function b2.Body:set_angular_velocity(value)
    box2d.b2Body_SetAngularVelocity(self._native, value)
end

--- @brief
function b2.Body:get_angular_velocity()
    return box2d.b2Body_GetAngularVelocity()
end

--- @brief
function b2.Body:apply_force(force, local_point_x, local_point_y, should_wake_up_body)
    if should_wake_up_body == nil then should_wake_up_body = true end
    if local_point_x == nil then local_point_x = 0 end
    if local_point_y == nil then local_point_y = 0 end
    box2d.b2Body_ApplyForce(self._native, ffi.typeof("b2Vec2")(local_point_x, local_point_y), should_wake_up_body)
end

--- @brief
function b2.Body:apply_torque(value, should_wake_up_body)
    if should_wake_up_body == nil then should_wake_up_body = true end
    box2d.b2Body_ApplyTorque(self._native, value, should_wake_up_body)
end

--- @brief
function b2.Body:apply_linear_impulse(impulse_x, impulse_y, local_point_x, local_point_y, should_wake_up_body)
    if should_wake_up_body == nil then should_wake_up_body = true end
    if local_point_x == nil then local_point_x = 0 end
    if local_point_y == nil then local_point_y = 0 end
    box2d.b2Body_ApplyLinearImpulse(self._native,
        ffi.typeof("b2Vec2")(impulse_x, impulse_y),
        ffi.typeof("b2Vec2")(local_point_x, local_point_y),
        should_wake_up_body
    )
end

--- @brief
function b2.Body:apply_angular_impulse(value, should_wake_up_body)
    if should_wake_up_body == nil then should_wake_up_body = true end
    box2d.b2Body_ApplyTorque(self._native, value, should_wake_up_body)
end

--- @brief
function b2.Body:get_mass()
    return box2d.b2Body_GetMass(self._native)
end

--- @brief
function b2.Body:override_mass_data(mass, center_x, center_y, rotational_inertia)
    box2d.b2Body_SetMassData(self._native, ffi.typeof("b2MassData")(
        mass,
        ffi.typeof("b2Vec2")(center_x, center_y),
        rotational_inertia
    ))
    box2d.b2Body_SetAutomaticMass(self._native, false);
end

--- @brief
function b2.Body:set_linear_damping(value)
    box2d.b2Body_SetLinearDamping(self._native, value)
end

--- @brief
function b2.Body:get_linear_damping()
    return box2d.b2Body_GetLinearDamping(self._native)
end

--- @brief
function b2.Body:set_angular_damping(value)
    box2d.b2Body_SetAngularDamping(self._native, value)
end

--- @brief
function b2.Body:get_angular_damping()
    return box2d.b2Body_GetAngularDamping(self._native)
end

--- @brief
function b2.Body:set_gravity_scale(x)
    box2d.b2Body_SetGravityScale(self._native, x)
end

--- @brief
function b2.Body:get_gravity_scale()
    return box2d.b2Body_GetGravityScale(self._native)
end

--- @brief
function b2.Body:set_is_bullet(b)
    box2d.b2Body_SetBullet(self._native, b)
end

--- @brief
function b2.Body:get_is_bullet()
    return box2d.b2Body_IsBullet()
end

--- @brief
function b2.Body:draw()
    assert(rt ~= nil and love.draw ~= nil)
    local color = rt.hsva_to_rgba(rt.HSVA(math.fmod((self._native.index1 / 16), 1), 1,1, 1));
    love.graphics.setColor(color.r, color.g, color.b, color.a)

    local n = box2d.b2Body_GetShapeCount(self._native)
    local shapes = ffi.new("b2ShapeId[" .. n .. "]")
    local _ = box2d.b2Body_GetShapes(self._native, shapes, n)
    local out = {}
    for i = 0, n-1 do
        b2.Shape:new_from_id(shapes[i]):draw()
    end
end
