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

    local world_id = ffi.gc(
        box2d.b2CreateWorld(def),
        box2d.b2DestroyWorld
    )

    return b2.World:new_from_id(world_id)
end

--- @brief
function b2.World:new_from_id(id)
    local out = setmetatable({
        _native = id,
        _debug_draw = ffi.typeof("b2DebugDraw")()
    }, {
        __index = b2.World
    })
    b2._initialize_debug_draw(out._debug_draw)
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

--- @brief
function b2._initialize_threads(world_def)
    sdl2 = ffi.load("SDL2")
    sdl2.cdef[[
    void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
    void SDL_WaitThread(void* thread, int *status);
    ]]

    -- void b2FinishTaskCallback( void* task, void* context );
    world_def.finishTask = function(task, context)
        if task ~= ffi.CNULL then
            sdl2.WaitThread()
        end
    end

    -- void* b2EnqueueTaskCallback( b2TaskCallback* task, int32_t itemCount, int32_t minRange, void* taskContext, void* userContext );
    world_def.enqueueTask = function()

    end
end