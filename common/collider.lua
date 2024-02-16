--- @class rt.ColliderType
rt.ColliderType = meta.new_enum({
    STATIC = "static",
    DYNAMIC = "dynamic",
    KINEMATIC = "kinematic"
})

-- compat for love12
function rt._fixture_get_shape(fixture)
    if love.getVersion() >= 12 then
        return fixture
    else
        return fixture:getShape()
    end
end

--- @class rt.Collider
--- @signal contact (self, rt.Collider, rt.ContactInfo) ->
--- @param world rt.PhysicsWorld
--- @param type rt.ColliderType
--- @param shape rt.PhysicsShape
rt.Collider = meta.new_type("Collider", rt.Drawable, rt.SignalEmitter, function(world, type, shapes, pos_x, pos_y)
    local out = meta.new(rt.Collider, {
        _shape_type = shape_type,
        _fixtures = {},    -- Table<love.physics.Fixture>
        _is_sensor = false,
        _world = world,
        _userdata = {}
    })

    out._body = love.physics.newBody(world._native, pos_x, pos_y, type)
    for _, shape in pairs(shapes) do
        table.insert(out._fixtures, love.physics.newFixture(out._body, shape._native, 1))
    end

    out:signal_add("contact_begin")
    out:signal_add("contact_end")

    out._userdata.self = out
    out:_update_userdata()
    return out
end)

--- @brief [internal]
function rt.Collider:_update_userdata()
    self._body:setUserData(self._userdata)
end

--- @brief
function rt.Collider:add_userdata(key, value)
    if key == "self" then
        rt.warning("In rt.Collider: overriding key `self`, which is reserved for rt.Collider")
    end
    self._userdata[key] = value
    self:_update_userdata()
end

--- @brief
function rt.Collider:get_userdata(key)
    return self._userdata[key]
end

--- @brief
--- @return Number, Number
function rt.Collider:get_position()
    return self._body:getPosition()
end

--- @brief
function rt.Collider:set_position(x, y)
    self._body:setPosition(x, y)
end

--- @brief
function rt.Collider:set_allow_sleeping(b)
    self._body:isSleepingAllowed(b)
end

--- @brief
function rt.Collider:get_bounds(i)
    if meta.is_nil(i) then
        local min_x, min_y = POSITIVE_INFINITY, POSITIVE_INFINITY
        local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY
        for j = 1, #self._fixtures do
            local x, y, bx, by = rt._fixture_get_shape(self._fixtures[j]):computeAABB(0, 0, 0)
            min_x = math.min(min_x, x)
            min_y = math.min(min_y, y)
            max_x = math.max(max_x, bx)
            max_y = math.max(max_y, by)
        end
        return rt.AABB(min_x, min_y, max_x - min_x, max_y - min_y)
    else
        local shape = rt._fixture_get_shape(self._fixtures[i])
        return rt.AABB(shape:computeAABB(0, 0, 0))
    end
end

--- @brief
function rt.Collider:destroy()
    self._body:destroy()
end

--- @brief
function rt.Collider:set_is_sensor(b)
    self._is_sensor = b
    for _, fixture in pairs(self._fixtures) do
        fixture:setSensor(b)
    end
end

--- @brief
function rt.Collider:get_is_sensor()
    return self._is_sensor
end

--- @brief
function rt.Collider:set_disabled(b)
    self._body:setActive(not b)
end

--- @brief apply impulse to center of mass
function rt.Collider:apply_linear_impulse(x, y)
    self._body:applyLinearImpulse(x, y)
end

--- @brief
function rt.Collider:apply_force(x, y)
    self._body:applyForce(x, y)
end

--- @brief
function rt.Collider:get_position()
    return self._body:getPosition()
end

--- @brief
function rt.Collider:set_linear_velocity(x, y)
    self._body:setLinearVelocity(x, y)
end

--- @brief
function rt.Collider:get_linear_velocity()
    return self._body:getLinearVelocity()
end

--- @brief
function rt.Collider:set_linear_damping(x, y)
    self._body:setLinearDamping(x, y)
end

--- @brief
function rt.Collider:get_linear_damping()
    return self._body:getLinearDamping()
end

--- @brief
function rt.Collider:get_centroid()
    local local_x, local_y = self._body:getLocalCenter()
    local x, y = self._body:getPosition()
    return x + local_x, y + local_y
end

--- @brief
function rt.Collider:set_centroid(x, y)
    self._body:setPosition(x, y)
end

--- @brief
function rt.Collider:set_mass(x)
    self._body:setMass(x)
end

--- @brief
function rt.Collider:get_mass()
    return self._body:getMass()
end

--- @brief
function rt.Collider:set_restitution(x, fixture_index)
    if meta.is_nil(fixture_index) then
        for _, fixture in pairs(self._fixtures) do
            fixture:setRestitution(x)
        end
    else
        self._fixtures[fixture_index]:setRestitution(x)
    end
end

--- @overload
function rt.Collider:draw()
    for i = 1, #self._fixtures do
        local shape = rt._fixture_get_shape(self._fixtures[i])
        local pos_x, pos_y = self._body:getPosition()
        rt.PhysicsShape._draw(shape, pos_x, pos_y)
    end
end

--- @brief rectangle, centroid is origin
function rt.RectangleCollider(world, type, top_left_x, top_left_y, width, height)
    local center_x, center_y = top_left_x + 0.5 * width, top_left_y + 0.5 * height
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.RECTANGLE,
        0, 0,
        width, height
    )
    return rt.Collider(world, type, {shape}, center_x, center_y)
end

--- @brief triangle, centroid is origin
--- @return rt.Collider
function rt.TriangleCollider(world, type, ax, ay, bx, by, cx, cy)
    local center_x, center_y = (ax + bx + by) / 3, (ay + by + cy) / 3
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.POLYGON,
        ax - center_x, ay - center_y,
        bx - center_x, by - center_y,
        cx - center_x, by - center_y
    )
    return rt.Collider(world, type, {shape}, center_x, center_y)
end


--- @brief triangle, centroid is origin
--- @return rt.Collider
function rt.PolygonCollider(world, type, ax, ay, bx, by, cx, cy, ...)
    local center_x, center_y = 0, 0
    local input = {ax, ay, bx, by, cx, cy, ...}
    for i = 1, #input, 2 do
        center_x = center_x + input[i+0]
        center_y = center_y + input[i+1]
    end
    center_x = center_x / (#input / 2)
    center_y = center_y / (#input / 2)

    local vertices = {}
    for i = 1, #input, 2 do
        vertices[i] = input[i] - center_x
        vertices[i+1] = input[i+1] - center_y
    end

    local shape = rt.PhysicsShape(rt.PhysicsShapeType.POLYGON, splat(vertices))
    return rt.Collider(world, type, {shape}, center_x, center_y)
end

--- @brief ellipse, centroid is origin
function rt.EllipseCollider(world, type, center_x, center_y, x_radius, y_radius, n_outer_vertices)
    n_outer_vertices = which(n_outer_vertices, 8)
    local step = 360 / n_outer_vertices
    local vertices = {}
    for angle = 0, 360, step do
        for p in range(
            0 + x_radius * math.cos(rt.degrees(angle):as_radians()),
            0 + y_radius * math.sin(rt.degrees(angle):as_radians())
        ) do table.insert(vertices, p) end
    end
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.POLYGON, splat(vertices))
    return rt.Collider(world, type, {shape}, center_x, center_y)
end

--- @brief circle collider, center is origin
--- @return rt.Collider
function rt.CircleCollider(world, type, center_x, center_y, radius)
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.CIRCLE, 0, 0, radius)
    return rt.Collider(world, type, {shape}, center_x, center_y)
end

--- @brief line segment, centroid is origin
--- @return rt.Collider
function rt.LineCollider(world, type, ax, ay, bx, by)
    local center_x, center_y = (ax + bx) / 2, (ay + by) / 2
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.LINE,
        ax - center_x, ay - center_y,
        bx - center_x, by - center_y
    )
    return rt.Collider(world, type, {shape}, center_x, center_y)
end



