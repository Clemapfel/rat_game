--- @class b2.World
b2.World = setmetatable({}, {
    __call = function(_, gravity_x, gravity_y, n_threads)
        return b2.World:new(gravity_x, gravity_y, n_threads)
    end
})

--- @brief
function b2.World:new(gravity_x, gravity_y, n_threads)
    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)

    if n_threads ~= nil then
        assert(type(n_threads) == "number" and n_threads > 0 and math.fmod(n_threads, 1) == 0)
        b2._initialize_threads(def, n_threads)
    end

    world_id = box2d.b2CreateWorld(def)
    --[[
    local world_id = ffi.gc(
        box2d.b2CreateWorld(def),
        box2d.b2DestroyWorld
    )
    ]]--

    return b2.World:new_from_id(world_id)
end

--- @brief
function b2.World:new_from_id(id)
    local out = setmetatable({
        _native = id
    }, {
        __index = b2.World
    })
    return out
end

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
