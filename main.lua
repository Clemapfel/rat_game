require("include")

rt.add_scene("debug")

local entities = rt.List()
local state = {}
for i = 1, 6 + 4 do
    local entity = bt._generate_debug_entity()
    entities:push_back(entity)
    state[i] = entity
end

order = bt.OrderQueue()
order:set_state(state)
rt.current_scene:set_child(order)

log = bt.BattleLog()
log:set_margin_top(rt.settings.margin_unit * 2)
log:set_margin_horizontal(200)
log:set_margin_bottom(200)

enemy = bt._generate_debug_entity()
sprite = bt.EnemySprite(enemy)
--sprite:set_margin(200)
rt.current_scene:set_child(sprite)

local size = 10
image = rt.Image(10, 10)
for x = 1, size do
    for y = 1, size do
        image:set_pixel(x, y, rt.HSVA(x / size, 1, 1, 1))
    end
end
particle_system = love.graphics.newParticleSystem(rt.Texture(image)._native)
particle_system:setParticleLifetime(0.1, 10)
particle_system:setEmissionRate(10)
particle_system:setLinearAcceleration(-100, -100, 100, 100)
particle_system:setPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
particle_system:start()

local m = 50
local w, h = love.graphics.getWidth() - 2 * m, love.graphics.getHeight() - 2 * m

points = {}
rt.random.seed(os.time(os.date("!*t")))

local n_points = 20
for i = 1, n_points do

    local r = rt.random.number(200, 300)

    local x, y = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    local angle = (i / n_points) * 360
    x = x + math.cos(rt.degrees(angle):as_radians()) * r
    y = y + math.sin(rt.degrees(angle):as_radians()) * r

    table.insert(points, x)
    table.insert(points, y)
end

local a1_x, a1_y = points[1], points[2]
local a2_x, a2_y = points[3], points[4]

local b1_x, b1_y = points[#points-1], points[#points]
local b2_x, b2_y = points[#points-3], points[#points-2]

points_a = {}
points_b = {}

local n = #points / 2
local indices = {}--{n-1, n}
for i in step_range(1, n, 2) do
    table.insert(indices, i)
end

for _, i in pairs(indices) do
    table.insert(points_a, points[i])
    table.insert(points_a, points[i+1])
end

points_b = {}
indices = {}
for i in step_range(1, n, 2) do
    table.insert(indices, i)
end

for _, i in pairs(indices) do
    table.insert(points_b, points[i])
    table.insert(points_b, points[i+1])
end

--[[
table.insert(points_b, points[1])
table.insert(points_b, points[2])
]]--

for x in range(b2_x, b2_y, b1_x, b1_y) do
    table.insert(points_b, x)
end

curve_a = rt.Spline(points_a)
curve_b = rt.Spline(points_b)

local wireframe = false;
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then
        local str = {}
        for i = 1, rt.random.integer(4) do
            table.insert(str, rt.random.string(rt.random.integer(4, 7)))
            table.insert(str, " ")
        end
        log:push_back("<wave>" .. string.rep("_", #str)  .. "</wave>")
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.UP then
        rt.settings.battle_background.dampening = rt.settings.battle_background.dampening + 0.1
        rt.settings.battle_background.dampening = clamp(rt.settings.battle_background.dampening, 0, 1)
    elseif which == rt.InputButton.DOWN then
        rt.settings.battle_background.dampening = rt.settings.battle_background.dampening - 0.1
        rt.settings.battle_background.dampening = clamp(rt.settings.battle_background.dampening, 0, 1)
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    end

    if which == rt.InputButton.A then
    end
end)

-- ######################

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    --love.graphics.clear(1, 0, 1, 1)
    --rt.current_scene:draw()

    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0, 1, 0.5)
    curve_a:draw()

    love.graphics.setColor(0, 1, 1, 0.5)
    curve_b:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
