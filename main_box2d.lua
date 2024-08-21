require "include"

--[[
sdl2 = ffi.load("SDL2")
ffi.cdef[[
void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
void SDL_WaitThread(void* thread, int *status);
]]

local box2d = ffi.load("box2d")
assert(box2d ~= nil)
local cdef, _ = love.filesystem.read("fast_physics/cdef.h")
ffi.cdef(cdef)

--- @brief
function b2_world_new(gravity_x, gravit_y)
    local world_def = box2d.b2DefaultWorldDef()
    world_def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravit_y)
    local world_id = ffi.gc(
        box2d.b2CreateWorld(world_def),
        box2d.b2DestroyWorld
    )
    return world_id
end

--- @brief
--- @return Number, Number
function b2_world_get_gravity(world)
    local out = box2d.b2World_GetGravity(world)
    return out.x, out.y
end

--- @brief
function b2_world_set_gravity(world, gravity_x, gravity_y)
    box2d.b2World_SetGravity(world, ffi.typeof("b2Vec2")(gravity_x, gravity_y))
end

--- @brief
function b2_world_step(world, delta, n_iterations)
    if n_iterations == nil then n_iterations = 4 end
    box2d.b2World_Step(world, delta, n_iterations)
end

--- @brief
--- @param centroid_x Number world coords
--- @param centroid_y Number world coords
function b2_body_new(world, centroid_x, centroid_y)
    local body_def = box2d.b2DefaultBodyDef()
    body_def.position = ffi.typeof("b2Vec2")(centroid_x, centroid_y)

    local body_id = box2d.b2Crea
end
