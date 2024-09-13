--- @class b2.World
b2.World = meta.new_type("PhysicsWorld", function(gravity_x, gravity_y)
    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)
    return meta.new(b2.World, {
        _native = box2d.b2CreateWorld(def)
    })
end)

--- @brief
--- @return Number, Number
function b2.World:get_gravity()
    local out = box2d.b2World_GetGravity(self._native)
    return out.x, out.y
end

--- @brief
function b2.World:set_gravity(gravity_x, gravity_y)
    box2d.b2World_SetGravity(self._native, ffi.typeof("b2Vec2")(gravity_x, gravity_y))
end

--- @brief
function b2.World:step(delta, n_iterations)
    if n_iterations == nil then n_iterations = 4 end
    box2d.b2World_Step(self._native, delta, n_iterations)
end

--- @brief
function b2.World:set_sleeping_enabled(b)
    box2d.b2World_EnableSleeping(self._native, b)
end

--- @brief
function b2.World:set_continuous_enabled(b)
    box2d.b2World_EnableContinuous(self._native, b)
end

--- @brief
function b2.World:draw()
    box2d.b2World_Draw(self._native, self._debug_draw)
end