--- @class rt.ColliderType
rt.ColliderType = meta.new_enum({
    STATIC = "static",
    DYNAMIC = "dynamic",
    KINEMATIC = "kinematic"
})

--- @class rt.Collider
--- @param world rt.PhysicsWorld
--- @param type rt.ColliderType
--- @param shape rt.Shape
rt.Collider = meta.new_type("Collider", function(world, type, shape, pos_x, pos_y)
    local out = meta.new(rt.Collider, {
        _shape_type = shape_type,
        _body = {},       -- love.physics.Body
        _fixtures = {},   -- Table<love.physics.Fixture>
        _world = world
    }, rt.Drawable)

    out._body = love.physics.newBody(world._native, pos_x, pos_y, type)
    table.insert(out._fixtures, love.physics.newFixture(out._body, shape._native, 1))
    return out
end)

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
function rt.Collider:destroy()
    self._body:destroy()
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
function rt.Collider:get_center_of_mass()
    local local_x, local_y = self._body:getLocalCenter()
    local x, y = self._body:getPosition()
    return x + local_x, y + local_y
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
        local shape = self._fixtures[i]:getShape()
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
    return rt.Collider(world, type, shape, center_x, center_y)
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
    return rt.Collider(world, type, shape, center_x, center_y)
end

--- @brief circle collider, center is origin
--- @return rt.Collider
function rt.CircleCollider(world, type, center_x, center_y, radius)
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.CIRCLE, 0, 0, radius)
    return rt.Collider(world, type, shape, center_x, center_y)
end

--- @brief line segment, centroid is origin
--- @return rt.Collider
function rt.LineCollider(world, type, ax, ay, bx, by)
    local center_x, center_y = (ax + bx) / 2, (ay + by) / 2
    local shape = rt.PhysicsShape(rt.PhysicsShapeType.LINE,
        ax - center_x, ay - center_y,
        bx - center_x, by - center_y
    )
    return rt.Collider(world, type, shape, center_x, center_y)
end