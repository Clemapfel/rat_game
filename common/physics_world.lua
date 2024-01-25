rt.settings.physics.world = {
    default_gravity = 200
}

--- @class rt.PhysicsWorld
rt.PhysicsWorld = meta.new_type("PhysicsWorld", function(x_gravity, y_gravity)
    return meta.new(rt.PhysicsWorld, {
        _native = love.physics.newWorld(which(x_gravity, 0), which(y_gravity, rt.settings.physics.world.default_gravity), true)
    })
end)

--- @brief
function rt.PhysicsWorld:update(delta)
    self._native:update(delta, 8, 4)
end

--- @brief
function rt.PhysicsWorld:set_gravity(x, y)
    self._native:setGravity(x, y)
end

--- @brief
function rt.PhysicsWorld:get_gravity()
    self._native:getGravity()
end