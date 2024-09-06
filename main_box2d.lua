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
require "fast_physics.world"
--require "fast_physics.world_thread_sdl"
require "fast_physics.world_thread_love"

n_threads = 8
world = b2.World:new_with_threads(0, 100, n_threads)
local bodies = {}
local radii = {}
local colors = {}
local floor = nil

love.load = function()
    local world_w, world_h = rt.graphics.get_width(), rt.graphics.get_height()
    local floor_body = b2.Body(world, b2.BodyType.STATIC, 0.5 * world_w, 0.5 * world_h)
    world_w = world_w * 0.9
    world_h = world_h * 0.9
    local left_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, -0.5 * world_h, -0.5 * world_w, 0.5 * world_h))
    local right_wall = b2.SegmentShape(floor_body, b2.Segment(0.5 * world_w, -0.5 * world_h, 0.5 * world_w, 0.5 * world_h))
    local top_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, -0.5 * world_h, 0.5 * world_w, -0.5 * world_h))
    local bottom_wall = b2.SegmentShape(floor_body, b2.Segment(-0.5 * world_w, 0.5 * world_h, 0.5 * world_w, 0.5 * world_h))

    floor = floor_body

    table.insert(bodies, floor_body)
    n_balls = 0
    spawn_ball = function()
        local margin = 0.3
        local x, y = rt.random.number(0.5 * rt.graphics.get_width() - margin * world_w, 0.5 * rt.graphics.get_width() + margin * world_w), rt.random.number(0.5 * rt.graphics.get_height() - margin * world_h, 0.5 * rt.graphics.get_height() + margin * world_h)
        local radius = rt.random.number(5, 10)
        local body = b2.Body(world, b2.BodyType.DYNAMIC, x, y)
        local shape = b2.CircleShape(body, b2.Circle(radius))
        shape:set_restitution(1.5)
        table.insert(bodies, body)
        table.insert(radii, radius)
        local color = rt.HSVA((n_balls % 256) / 256, 1, 1, 1)
        table.insert(colors, {rt.color_unpack(rt.hsva_to_rgba(color))})
        n_balls = n_balls + 1
    end

    for i = 1, 2000 do
        spawn_ball()
    end
end

sum = 0
n = 0

love.update = function(dt)
    if love.keyboard.isDown("space") then
        --spawn_ball()
    end

    if love.keyboard.isDown("space") then
        clock = rt.Clock()
        world:step(dt, 2)
        dbg(N_TASKS)
        sum = sum + clock:restart():as_seconds() / (1 / 60)
        n = n + 1
        dbg(sum / n)
    end
end

love.draw = function()
    floor:draw()
    for i = 1, n_balls do
        local x, y = bodies[i]:get_centroid()
        local radius = radii[i]
        love.graphics.setColor(table.unpack(colors[i]))
        love.graphics.circle("line", x, y, radius)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(love.timer.getFPS() .. " fps | " .. n_balls .. " balls | " .. n_threads .. " threads", 5, 5)
end

--[[
local channel = love.thread.newChannel()
local allocated = ffi.new("int32_t[3]")
allocated[1] = 1234
allocated[2] = -1234
allocated[3] = 4567

channel:push(tonumber(ffi.cast("uint64_t", allocated)))

local popped = ffi.cast("int32_t*", channel:pop())
dbg(popped[1], popped[2], popped[3])
]]--

