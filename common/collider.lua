--- @class rt.ColliderType
rt.ColliderType = meta.new_enum({
    STATIC = "static",
    DYNAMIC = "dynamic",
    KINEMATIC = "kinematic"
})

--- @class rt.ColliderCollisionGroup
--- @brief only objects in the same group collide
rt.ColliderCollisionGroup = meta.new_enum({
    NONE = -1,
    ALL = 0,
    GROUP_01 = bit.lshift(1, 0),
    GROUP_02 = bit.lshift(1, 1),
    GROUP_03 = bit.lshift(1, 2),
    GROUP_04 = bit.lshift(1, 3),
    GROUP_05 = bit.lshift(1, 4),
    GROUP_06 = bit.lshift(1, 5),
    GROUP_07 = bit.lshift(1, 6),
    GROUP_08 = bit.lshift(1, 7),
    GROUP_09 = bit.lshift(1, 8),
    GROUP_10 = bit.lshift(1, 9),
    GROUP_11 = bit.lshift(1, 10),
    GROUP_12 = bit.lshift(1, 11),
    GROUP_13 = bit.lshift(1, 12),
    GROUP_14 = bit.lshift(1, 13),
    GROUP_15 = bit.lshift(1, 14),
    GROUP_16 = bit.lshift(1, 15)
})

--- @class rt.Collider
--- @signal contact_begin (self, rt.Collider, rt.ContactInfo) -> nil
--- @signal contact_end (self, rt.Collider, rt.ContactInfo) -> nil
--- @param world rt.PhysicsWorld
--- @param type rt.ColliderType
--- @param shape rt.PhysicsShape
rt.Collider = meta.new_type("Collider", rt.Drawable, rt.SignalEmitter, function(world, type, pos_x, pos_y)
    local out = meta.new(rt.Collider, {
        _fixtures = {},    -- Table<love.physics.Fixture>
        _is_sensor = false,
        _world = world,
        _userdata = {},
        _body = {}
    })

    out._body = love.physics.newBody(world._native, pos_x, pos_y, type)

    out:signal_add("contact_begin")
    out:signal_add("contact_end")

    out._userdata.self = out
    out:_update_userdata()
    return out
end)

--- @brief
function rt.Collider:add_userdata(key, value)
    if key == "self" then
        rt.error("In rt.Collider:add_userdata: key `self` is reserved and cannot be overriden")
    end
    self._userdata[key] = value
    self._update_userdata()
end

--- @brief
function rt.Collider:get_userdata(key)
    return self._userdata[key]
end

--- @brief
function rt.Collider:has_userdata(key)
    return self._userdata[key] ~= nil
end

--- @brief
function rt.Collider:add_rectangle(x, y, width, height, angle)
    if love.getVersion() >= 12 then
        table.insert(self._fixtures, love.physics.newRectangleShape(self._body, x, y, width, height, angle))
    else
        local shape = love.physics.newRectangleShape(x, y, width, height, angle)
        table.insert(self._fixtures, love.physics.newFixture(self._body, shape, 1))
    end
end

--- @brief
function rt.RectangleCollider(world, type, x, y, width, height, angle)
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local out = rt.Collider(world, type, center_x, center_y)
    out:add_rectangle(0, 0, width, height)
    return out
end

--- @brief
function rt.Collider:add_circle(x, y, radius)
    if love.getVersion() >= 12 then
        table.insert(self._fixtures, love.physics.newCircleShape(self._body, x, y, radius))
    else
        local shape = love.physics.newCircleShape(x, y, radius)
        table.insert(self._fixtures, love.physics.newFixture(self._body, shape, 1))
    end
end

--- @brief
function rt.CircleCollider(world, type, center_x, center_y, radius)
    local out = rt.Collider(world, type, center_x, center_y)
    out:add_circle(0, 0, radius)
    return out
end

--- @brief 
function rt.Collider:add_line(ax, ay, bx, by, ...)
    if _G._select("#", ...) == 0 then
        if love.getVersion() >= 12 then
            table.insert(self._fixtures, love.physics.newEdgeShape(self._body, ax, ay, bx, by))
        else
            local shape = love.physics.newEdgeShape(ax, ay, bx, by)
            table.insert(self._fixtures, love.physics.newFixture(self._body, shape, 1))
        end
    else
        if love.getVersion() >= 12 then
            table.insert(self._fixtures, love.physics.newChainShape(self._body, false, ax, ay, bx, by, ...))
        else
            local shape = love.physics.newChainShape(false, ax, ay, bx, by, ...)
            table.insert(self._fixtures, love.physics.newFixture(self._body, shape, 1))
        end
    end
end

--- @brief line segment, centroid is origin
--- @return rt.Collider
function rt.LineCollider(world, type, ax, ay, bx, by, ...)
    local center_x, center_y = 0, 0
    local input = {ax, ay, bx, by, ...}
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

    local out = rt.Collider(world, type, center_x, center_y)
    out:add_line(splat(vertices))
    return out
end

--- @brief
function rt.Collider:add_polygon(...)
    if love.getVersion() >= 12 then
        table.insert(self._fixtures, love.physics.newPolygonShape(self._body,...))
    else
        local shape = love.physics.newPolygonShape(...)
        table.insert(self._fixtures, love.physics.newFixture(self._body, shape, 1))
    end
end

--- @brief
function rt.TriangleCollider(world, type, ax, ay, bx, by, cx, cy)
    local center_x, center_y = (ax + bx + by) / 3, (ay + by + cy) / 3
    local out = rt.Collider(world, type, center_x, center_y)
    out:add_polygon(
        ax - center_x, ay - center_y,
        bx - center_x, by - center_y,
        cx - center_x, by - center_y
    )
    return out
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

    local out = rt.Collider(world, type, center_x, center_y)
    out:add_polygon(splat(vertices))
    return out
end

--- @brief
function rt.Collider:_draw_shape(shape)
    local body_x, body_y = self:get_position()

    love.graphics.push()
    rt.graphics.set_blend_mode(rt.BlendMode.NORMAL)
    love.graphics.setColor(1, 1, 1, 1)

    local type = shape:type()
    if type == "PolygonShape" then
        local local_points = {shape:getPoints()}
        for i = 1, #local_points, 2 do
            local_points[i+0] = local_points[i+0] + body_x
            local_points[i+1] = local_points[i+1] + body_y
        end

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.polygon("fill", table.unpack(local_points))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.polygon("line", table.unpack(local_points))

    elseif type == "CircleShape" then
        local x, y = shape:getPoint()
        x = x + body_x
        y = y + body_y
        local radius = shape:getRadius()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", x, y, radius)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("line", x, y, radius)
    elseif type == "EdgeShape" then
        local ax, ay, bx, by = shape:getPoints()
        ax = ax + body_x
        ay = ay + body_y
        bx = bx + body_x
        by = by + body_y
        love.graphics.line(ax, ay, bx, by)
    elseif type == "ChainShape" then
        local local_points = {shape:getPoints()}
        for i = 1, #local_points, 2 do
            local_points[i+0] = local_points[i+0] + body_x
            local_points[i+1] = local_points[i+1] + body_y
        end
        love.graphics.line(table.unpack(local_points))
    end

    love.graphics.pop()
end

--- @overload
function rt.Collider:draw()
    if love.getVersion() >= 12 then
        for _, shape in pairs(self._fixtures) do
            self:_draw_shape(shape)
        end
    else
        for i = 1, #self._fixtures do
            local shape = self._fixtures[i]:getShape()
            self:_draw_shape(shape)
        end
    end
end

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

--- @brief
function rt.Collider:set_is_active(b)
    self._body:setActive(b)
end

--- @brief
function rt.Collider:get_is_active()
    return self._body:getActive()
end

--- @brief
function rt.Collider:set_collision_group(group)
    if love.getVersion() >= 12 then
        for _, shape in pairs(self._body:getShapes()) do
            if group == rt.ColliderCollisionGroup.ALL then
                shape:setFilterData(0xFFFF, 0xFFFF, 0)
            elseif group == rt.ColliderCollisionGroup.NONE then
                shape:setFilterData(0x0, 0x0, 0)
            else
                shape:setFilterData(group, group, 0)
            end
        end
    else
        for _, shape in pairs(self._body:getFixtures()) do
            shape:setFilterData(group, group, 0)
        end
    end
end
