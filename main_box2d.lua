require "include"

box2d = ffi.load("box2d")
local cdef, _ = love.filesystem.read("fast_physics/cdef.h")
ffi.cdef(cdef)

require "fast_physics.world"
require "fast_physics.body"
require "fast_physics.circle"
require "fast_physics.polygon"
require "fast_physics.capsule"
require "fast_physics.segment"
require "fast_physics.shape"
require "fast_physics.draw"

world = b2.World(0, 10, 8)

body = b2.Body(world, b2.BodyType.DYNAMIC, 300, 300)
shape = b2.PolygonShape(body, b2.Rectangle(100, 100))
--shape = b2.ChainShape(body, 50, 50, 250, 50, 250, 250, 50, 250)
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
    world:draw()
end