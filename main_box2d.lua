require "include"

box2d = ffi.load("box2d")
local cdef = love.filesystem.read("fast_physics/cdef.h")
ffi.cdef(cdef)
box2d.b2SetLengthUnitsPerMeter(20)

require "fast_physics.capsule"
require "fast_physics.circle"
require "fast_physics.polygon"
require "fast_physics.segment"
require "fast_physics.shape"
require "fast_physics.body"
require "fast_physics.world"
--require "fast_physics.world_thread_sdl"
--require "fast_physics.world_thread_love"
require "fast_physics.world_thread_enki"

BENCHMARK = false
if BENCHMARK then
    for n_threads in range(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) do
        world = b2.World:new_with_threads(0, 100, n_threads)
        local bodies = {}
        local radii = {}
        local colors = {}
        local floor = nil

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

        sum = 0
        n = 0

        for i = 1, 5 * 60 do
            clock = rt.Clock()
            world:step(1 / 60, 4)
            sum = sum + clock:restart():as_seconds() / (1 / 60)
            n = n + 1
        end

        dbg(n_threads, sum / n)
    end
else
    n_threads = 8
    world = b2.World:new_with_threads(0, 100, n_threads)

    local center_x, center_y = 0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height()
    local world_w, world_h = 0.75 * rt.graphics.get_width(), 0.75 * rt.graphics.get_height()

    local floor_radius = 0.4 * world_w
    local floor_body = b2.Body(world, b2.BodyType.STATIC, center_x, center_y)
    local floor_shapes = {}

    do
        local top_right_x, top_right_y = 0.5 * world_w, -0.5 * world_h
        local bottom_right_x, bottom_right_y = 0.5 * world_w, 0.5 * world_h
        local bottom_left_x, bottom_left_y = -0.5 * world_w, 0.5 * world_h
        local top_left_x, top_left_y = -0.5 * world_w, -0.5 * world_h
        local floor_top = b2.SegmentShape(floor_body, b2.Segment(top_left_x, top_left_y, top_right_x, top_right_y))
        local floor_right = b2.SegmentShape(floor_body, b2.Segment(top_right_x, top_right_y, bottom_right_x, bottom_right_y))
        local floor_bottom = b2.SegmentShape(floor_body, b2.Segment(bottom_right_x, bottom_right_y, bottom_left_x, bottom_left_y ))
        local floor_left = b2.SegmentShape(floor_body, b2.Segment(bottom_left_x, bottom_left_y, top_left_x, top_left_y))

        floor_shapes = {floor_top, floor_right, floor_bottom, floor_left}
    end

    local n_balls = 0
    local target_n_balls = 1200
    local n_rows = math.floor(math.sqrt(target_n_balls))
    local n_columns = n_rows

    local ball_bodies = {}
    local ball_shapes = {}

    local total_item_w, total_item_h = 0.2 * world_w, 0.2 * world_h
    local item_x, item_y = 0.5 * world_w - 0.5 * total_item_w, 0.5 * world_h - 0.5 * total_item_h
    item_x = item_x / (world_h / world_w)
    local item_w, item_h = total_item_w / n_columns, total_item_h / n_rows
    item_w = item_w / (world_h / world_w)

    do
        local direction = true
        for row_i = 1, n_rows do
            for col_i = 1, n_columns do
                local pos_x, pos_y = item_x + (col_i - 1) * item_w, item_y + 0.5 * item_h + (row_i - 1) * item_h
                local body = b2.Body(world, b2.BodyType.DYNAMIC, pos_x, pos_y)
                local shape = b2.CircleShape(body, b2.Circle(item_w / 8))
                --local shape = b2.CapsuleShape(body, b2.Capsule(pos_x - 0.5 * item_w, pos_y, pos_x + 0.5 * item_w, pos_y, 0.5 * item_w))
                shape:set_restitution(0.3)
                body:set_is_fixed_rotation(true)
                table.insert(ball_bodies, body)
                table.insert(ball_shapes, shape)

                body:set_type(b2.BodyType.KINEMATIC)

                n_balls = n_balls + 1
            end
            direction = not direction
        end
    end

    local colors = {}
    for i = 1, n_balls do
        local r, g, b, a = rt.color_unpack(rt.hsva_to_rgba(rt.HSVA((i - 1) / n_balls, 1, 1, 1)))
        table.insert(colors, r)
        table.insert(colors, g)
        table.insert(colors, b)
        table.insert(colors, a)
    end

    local ball_i = n_balls
    love.keypressed = function(key)
        if key == "d" then
            for body in values(ball_bodies) do
                body:set_type(b2.BodyType.DYNAMIC)
                local centroid_x, centroid_y = body:get_centroid()
                local angle = rt.angle(centroid_x - (item_x + 0.5 * total_item_w), centroid_y - (item_y + 0.5 * total_item_h))
                body:apply_linear_impulse(rt.translate_point_by_angle(centroid_x, centroid_y, 700, angle))
            end
        elseif key == "b" then
            for body in values(ball_bodies) do
                body:apply_linear_impulse(0, -400 * rt.random.number(1, 2))
            end
        end
    end

    love.update = function(dt)
        clock = rt.Clock()

        if love.keyboard.isDown("space") then
            local body = ball_bodies[ball_i]
            ball_i = ball_i - 1
            body:set_type(b2.BodyType.DYNAMIC)
            local centroid_x, centroid_y = body:get_centroid()
            local angle = rt.angle(centroid_x - (item_x + 0.5 * total_item_w), centroid_y - (item_y + 0.5 * total_item_h))
            body:apply_linear_impulse(0, 500)
        end

        world:step(dt * 1.5, 6)
        println(clock:restart():as_seconds() / (1 / 60))
    end

    love.draw = function()
        for floor in values(floor_shapes) do
            floor:draw()
        end

        love.graphics.setColor(rt.color_unpack(rt.Palette.RED))
        local color_i = 1
        for i = 1, n_balls do
            local position_x, position_y = ball_bodies[i]:get_centroid()
            love.graphics.setColor(colors[color_i], colors[color_i + 1], colors[color_i + 2], colors[color_i + 3])
            love.graphics.circle("line", position_x, position_y, item_w)
            color_i = color_i + 4
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(love.timer.getFPS() .. " fps | " .. n_balls .. " balls | " .. n_threads .. " threads", 5, 5)
    end
end