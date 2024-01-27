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
function rt.PhysicsWorld:update(delta, velocity_iterations, position_iterations)
    self._native:update(delta, which(velocity_iterations, 8), which(position_iterations, 4))
end

--- @brief
function rt.PhysicsWorld:set_gravity(x, y)
    self._native:setGravity(which(x, 0), which(y, 0))
end

--- @brief
function rt.PhysicsWorld:get_gravity()
    self._native:getGravity()
end