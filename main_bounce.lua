require "include"

local lp = love.physics

local world = lp.newWorld(0, 0);
lp.setMeter(80)
world:setCallbacks(nil, nil,
-- presolve
    function(a, b, contact)
        dbg(math.deg(rt.angle(contact:getNormal())))
    end,

-- post_solve
    function(a, b, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
    end
)

local category_ball, category_other = 1, 2

local w, h = love.graphics.getDimensions()
local ground_y = 0.5 * h
local ground_body = lp.newBody(world, 0.5 * w, ground_y, "dynamic")
local ground_shape = lp.newEdgeShape(ground_body, -0.25 * w, 0, 0.25 * w, 0)
ground_shape:setCategory(category_other)
ground_shape:setRestitution(2)

local ball_r = 10
local spawn_x, spawn_y = 50, ground_y - 100 - 2 * ball_r
local spawn_angle = math.rad(0)
local line_x, line_y = rt.translate_point_by_angle(spawn_x, spawn_y, 50, spawn_angle)

local n_balls = 0
local ball_bodies = {}
local ball_shapes = {}
local ball_rgba = {}

local angle_delta, position_delta = 0.05, 5

love.update = function(delta)
    if love.keyboard.isDown("up") then
        spawn_y = spawn_y - position_delta
    elseif love.keyboard.isDown("down") then
        spawn_y = spawn_y + position_delta
    elseif love.keyboard.isDown("left") then
        spawn_x = spawn_x - position_delta
    elseif love.keyboard.isDown("right") then
        spawn_x = spawn_x + position_delta
    end

    world:update(delta)
end

love.keypressed = function(key)
    if key == "space" then
        local ball_body = lp.newBody(world, spawn_x, spawn_y, "dynamic")
        local ball_shape = lp.newCircleShape(ball_body, ball_r)
        local velocity_x, velocity_y = rt.translate_point_by_angle(0, 0, 100, spawn_angle)
        ball_body:setLinearVelocity(velocity_x, velocity_y)
        ball_shape:setRestitution(1.5)
        ball_shape:setCategory(category_ball)
        ball_shape:setMask(category_ball)

        n_balls = n_balls + 1
        table.insert(ball_bodies, ball_body)
        table.insert(ball_shapes, ball_shape)
        table.insert(ball_rgba, {rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(rt.random.number(0, 1), 1, 1, 1)))})
    end

    if key == "x" then
        spawn_angle = spawn_angle + angle_delta
    elseif key == "y" then
        spawn_angle = spawn_angle - angle_delta
    end
    dbg(spawn_angle)
end

love.draw = function()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(ground_body:getWorldPoints(ground_shape:getPoints()))

    for i = 1, n_balls do
        love.graphics.setColor(table.unpack(ball_rgba[i]))
        local x, y = ball_bodies[i]:getPosition()
        love.graphics.circle("line", x, y, ball_r)
    end

    love.graphics.setPointSize(4)
    love.graphics.points(spawn_x, spawn_y)
    love.graphics.line(spawn_x, spawn_y, rt.translate_point_by_angle(spawn_x, spawn_y, 50, spawn_angle))
end

--[[
require "include"

local world = b2.World(0, 0);

local category_ball, category_other = 1, 2

local w, h = love.graphics.getDimensions()
local ground_y = 0.5 * h
local ground_body = b2.Body(world, b2.BodyType.DYNAMIC, 0.5 * w, ground_y)
local ground_shape = b2.SegmentShape(ground_body, b2.Segment(-0.25 * w, 0, 0.25 * w, 0))

local ball_r = 5
local spawn_x, spawn_y = 50, ground_y - 100 - 2 * ball_r
local spawn_angle = math.rad(0)
local line_x, line_y = rt.translate_point_by_angle(spawn_x, spawn_y, 50, spawn_angle)

local n_balls = 0
local ball_bodies = {}
local ball_shapes = {}
local ball_rgba = {}

local angle_delta, position_delta = 0.05, 5

love.update = function(delta)
    if love.keyboard.isDown("up") then
        spawn_y = spawn_y - position_delta
    elseif love.keyboard.isDown("down") then
        spawn_y = spawn_y + position_delta
    elseif love.keyboard.isDown("left") then
        spawn_x = spawn_x - position_delta
    elseif love.keyboard.isDown("right") then
        spawn_x = spawn_x + position_delta
    end

    world:step(delta)
end

love.keypressed = function(key)
    if key == "space" then
        local ball_body = b2.Body(world, b2.BodyType.DYNAMIC, spawn_x, spawn_y)
        local ball_shape = b2.CircleShape(ball_body, b2.Circle(ball_r))
        ball_body:set_linear_velocity(rt.translate_point_by_angle(0, 0, 100, spawn_angle))
        ball_shape:set_restitution(1)

        n_balls = n_balls + 1
        table.insert(ball_bodies, ball_body)
        table.insert(ball_shapes, ball_shape)
        table.insert(ball_rgba, {rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(rt.random.number(0, 1), 1, 1, 1)))})
    end

    if key == "x" then
        spawn_angle = spawn_angle + angle_delta
    elseif key == "y" then
        spawn_angle = spawn_angle - angle_delta
    end
end

love.draw = function()
    world:draw()

    love.graphics.setPointSize(4)
    love.graphics.points(spawn_x, spawn_y)
    love.graphics.line(spawn_x, spawn_y, rt.translate_point_by_angle(spawn_x, spawn_y, 50, spawn_angle))
end
]]--