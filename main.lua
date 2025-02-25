require "include"
require "physics.physics"

local world
local bodies = {}

love.load = function()
    world = b2.World(0, 10, 8)
    for i = 1, 100 do
        local body = b2.Body(world, b2.BodyType.DYNAMIC, love.math.random(), love.math.random())
        local shape = b2.CircleShape()
    end
end