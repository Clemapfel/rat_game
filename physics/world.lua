--- @class b2.World
b2.World = meta.new_type("PhysicsWorld", function(gravity_x, gravity_y)
    local def = box2d.b2DefaultWorldDef()
    def.gravity = b2.Vec2(gravity_x, gravity_y)
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
    box2d.b2World_SetGravity(self._native, b2.Vec2(gravity_x, gravity_y))
end

--- @brief
function b2.World:step(delta, n_iterations)
    if n_iterations == nil then n_iterations = 4 end

    local step = 1 / 60
    while delta > step do
        box2d.b2World_Step(self._native, step, n_iterations)
        delta = delta - step
    end
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

--- @brief
function b2.World._raycast_callback(shape_id_ptr, point_ptr, normal_ptr, fraction, context_ptr)
    return 0
end

--- @brief
function b2.World:raycast(origin_x, origin_y, end_x, end_y)
    local origin_point = b2.Vec2(origin_x, origin_y)
    local translation = b2.Vec2(end_x - origin_x, end_y - origin_y)

    box2d.b2World_CastRay(
        self._native,
        origin_point, translation,
        box2d.b2DefaultQueryFilter(),
        ffi.cast("b2CastResultFcn*", b2.World._raycast_callback),
        ffi.CNULL
    )
end