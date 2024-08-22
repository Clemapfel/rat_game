require "include"

box2d = ffi.load("box2d")
assert(box2d ~= nil)
local cdef, _ = love.filesystem.read("fast_physics/cdef.h")
ffi.cdef(cdef)

require "fast_physics.world"
require "fast_physics.body"
require "fast_physics.circle"
require "fast_physics.polygon"
require "fast_physics.capsule"
require "fast_physics.segment"
require "fast_physics.shape"

--[[
sdl2 = ffi.load("SDL2")
ffi.cdef[[
void* SDL_CreateThread(int(*fn)(void*), const char *name, void *data);
void SDL_WaitThread(void* thread, int *status);
]]

world = b2.World(0, 10)

local circle = b2.Circle(10, 300, 300)
local segment = b2.Segment(50, 50, rt.graphics.get_width(), rt.graphics.get_height())
local capsule = b2.Capsule(200, 200, 500, 100, 20)
local rectangle = b2.Rectangle(100, 100, 400, 400)

local polygon = b2.Polygon(200, 300, 250, 500, 300, 400)

body = b2.Body(world, b2.BodyType.DYNAMIC, 300, 300)
shape = b2.PolygonShape(body, b2.Rectangle(100, 100))

love.load = function()
    love.window.setMode(800, 600, {
        msaa = 8
    })
end

love.update = function(delta)
    world:step(delta, 4)
end

love.draw = function()
    love.graphics.setColor(1, 1, 1, 0.5)
    shape:draw()
end