require "include"

box2d = ffi.load("box2d")
local cdef = love.filesystem.read("fast_physics/cdef.h")
ffi.cdef(cdef)

require "fast_physics.capsule"
require "fast_physics.circle"
require "fast_physics.polygon"
require "fast_physics.segment"
require "fast_physics.shape"
require "fast_physics.body"
require "fast_physics.threads"
require "fast_physics.world"

world = b2.World(0, 100, 3)
local to_draw = {}

love.load = function()
    local world_w, world_h = rt.graphics.get_width(), rt.graphics.get_height()
    local floor_body = b2.Body(world, b2.BodyType.STATIC, 0.5 * world_w, 0.5 * world_h)
    world_w = world_w * 0.9
    world_h = world_h * 0.9
    local left_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, -0.5 * world_h, -0.5 * world_w, 0.5 * world_h))
    local right_wall = b2.SegmentShape(floor_body, b2.Segment(0.5 * world_w, -0.5 * world_h, 0.5 * world_w, 0.5 * world_h))
    local top_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, -0.5 * world_h, 0.5 * world_w, -0.5 * world_h))
    local bottom_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, 0.5 * world_h, 0.5 * world_w, 0.5 * world_h))

    for wall in range(left_wall, right_wall, top_wall, bottom_wall) do
        table.insert(to_draw, body)
    end

    table.insert(to_draw, floor_body)
    n_balls = 0
    spawn_ball = function()
        local x, y = rt.random.number(0.2 * world_w, (1 - 0.2) * world_w), rt.random.number(0.2 * world_h, (1 - 0.2) * world_h)
        local radius = rt.random.number(5, 10)
        local body = b2.Body(world, b2.BodyType.DYNAMIC, x, y)
        local shape = b2.CircleShape(body, b2.Circle(radius))
        shape:set_restitution(0.9)
        table.insert(to_draw, body)
        n_balls = n_balls + 1
    end

    for i = 1, 1000 do
        spawn_ball()
    end
end

love.update = function(dt)
    if love.keyboard.isDown("space") then
        spawn_ball()
    end

    clock = rt.Clock()
    world:step(dt, 4)
    dbg(clock:restart():as_seconds() / (1 / 60))
end

love.draw = function()
    for drawable in values(to_draw) do
        drawable:draw()
    end
end