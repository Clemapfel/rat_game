rt.settings.physics.world = {
    default_gravity = 200
}

--- @class rt.PhysicsWorld
--- @signal update (self) -> nil
rt.PhysicsWorld = meta.new_type("PhysicsWorld", rt.SignalEmitter, function(x_gravity, y_gravity)
    local out = meta.new(rt.PhysicsWorld, {
        _native = love.physics.newWorld(
            which(x_gravity, 0),
            which(y_gravity, rt.settings.physics.world.default_gravity),
            false
        )
    })
    out:signal_add("update")

    out._native:setCallbacks(
        rt.PhysicsWorld._on_begin_contact,
        rt.PhysicsWorld._on_end_contact,
        rt.PhysicsWorld._on_pre_solve,
        rt.PhysicsWorld._on_post_solve
    )
    return out
end)

--- @class PhysicsContactInfo
rt.PhysicsContactInfo = meta.new_type("PhysicsContactInfo", function(love_contact)
    return meta.new(rt.PhysicsContactInfo, {
        _native = love_contact
    })
end)


--- @brief [internal]
function rt.PhysicsWorld._on_begin_contact(fixture_a, fixture_b, contact)
    local a_userdata = fixture_a:getBody():getUserData()
    local b_userdata = fixture_b:getBody():getUserData()
    local a = a_userdata.self
    local b = b_userdata.self

    b:signal_emit("contact_begin", a, rt.PhysicsContactInfo(contact))
    a:signal_emit("contact_begin", b, rt.PhysicsContactInfo(contact))
end

--- @brief
function rt.PhysicsWorld._on_end_contact(fixture_a, fixture_b, contact)
    local a_userdata = fixture_a:getBody():getUserData()
    local b_userdata = fixture_b:getBody():getUserData()
    local a = a_userdata.self
    local b = b_userdata.self

    b:signal_emit("contact_end", a, rt.PhysicsContactInfo(contact))
    a:signal_emit("contact_end", b, rt.PhysicsContactInfo(contact))
end

--- @brief
function rt.PhysicsWorld._on_pre_solve(fixture_a, fixture_b, contact)
end

--- @brief
function rt.PhysicsWorld._on_post_solve(fixture_a, fixture_b, contact)
end

--- @brief
function rt.PhysicsWorld:update(delta, velocity_iterations, position_iterations)
    self._native:update(delta, which(velocity_iterations, 8), which(position_iterations, 4))
    self:signal_emit("update")
end

--- @brief
function rt.PhysicsWorld:set_gravity(x, y)
    self._native:setGravity(which(x, 0), which(y, 0))
end

--- @brief
function rt.PhysicsWorld:get_gravity()
    self._native:getGravity()
end

