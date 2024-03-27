require "include"

rt.SpriteAtlas = rt.SpriteAtlas()
rt.SpriteAtlas:initialize("assets/sprites")

rt.SoundAtlas = rt.SoundAtlas()
rt.SoundAtlas:initialize("assets/sound_effects")

local world = rt.PhysicsWorld(0, 0)

local boundaries = {}
local w, h = rt.graphics.get_width(), rt.graphics.get_height()
table.insert(boundaries, rt.LineCollider(world, rt.ColliderType.STATIC, 0, 0, w, 0))
table.insert(boundaries, rt.LineCollider(world, rt.ColliderType.STATIC, w, 0, w, h))
table.insert(boundaries, rt.LineCollider(world, rt.ColliderType.STATIC, w, h, 0, h))
table.insert(boundaries, rt.LineCollider(world, rt.ColliderType.STATIC, 0, h, 0, 0))

local tail = {}
local joints = {}
local x, y, w, h = 100, 100, 250, 10
local total_w = 100
local n = 50
local w = total_w / n
local overlap = 0.1

local joint_x, joint_y
for i = 0, n do
    local collider = rt.RectangleCollider(
        world, rt.ColliderType.DYNAMIC,
        x + i * w - overlap * w, y, ternary(i == n, w * 2, w), h
    )
    collider:set_mass(0)
    collider:set_collision_group(rt.ColliderCollisionGroup.NONE)
    table.insert(tail, collider)

    if i > 0 and i <= n then
        joint_x, joint_y = x + (i-1) * w - overlap * w + w, y + 0.5 * h
        local joint = rt.Joint(
            rt.JointType.PIVOT,--ternary(i == n, rt.JointType.FIXED, rt.JointType.PIVOT),
            tail[i+1], tail[i+1-1],
            joint_x, joint_y
        )
        table.insert(joints, joint)
        --joint._native:setStiffness(0)
        --joint._native:setDamping(1)
    end
end

local scene_dummy = {
    _world = world,
    get_debug_draw_enabled = function() return true end
}

joint_x, joint_y = x + (#joints) * w - overlap * w + w, y + 0.5 * h
local player = ow.Player(scene_dummy, joint_x, joint_y)
player:realize()

table.insert(joints, rt.Joint(
    rt.JointType.FIXED,
    player._collider,
    tail[#tail],
    joint_x, joint_y
))

local history = {}
local last_position_x, last_position_y = player:get_position()

for i = 1, n+1 do
    table.insert(history, last_position_x)
    table.insert(history, last_position_y)
end

local elapsed = 0
local step = 1 / 10

spline = nil
function update_spline()
    local vertices = {}
    for body in values(tail) do
        local x, y = body:get_position()
        table.insert(vertices, x)
        table.insert(vertices, y)
    end

    --[[
    local mix_weight = 0.5
    for i = 1, #vertices, 2 do
        vertices[i] = mix(vertices[i], history[i], mix_weight)
        vertices[i+1] = mix(vertices[i+1], history[i+1], mix_weight)
    end
    ]]--
    spline = rt.Spline(vertices)
end
update_spline()

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
end

love.draw = function()
    love.graphics.clear(0.8, 0.2, 0.8, 1)

    do -- show fps
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end

    for c in values(tail) do
        --c:draw()
    end

    for c in values(joints) do
        --c:draw()
    end

    love.graphics.setLineWidth(5)
    local color = rt.Palette.PURPLE_1
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    spline:draw()

    player:draw()

    if tail_spline ~= nil then
        love.graphics.setLineWidth(5)
        local color = rt.Palette.PURPLE_1
        love.graphics.setColor(color.r, color.g, color.b, color.a)
        tail_spline:draw()
        love.graphics.points(history)
    end
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    world:update(delta, 20, 20)
    player:update(delta)
    update_spline()

    local current_x, current_y = player:get_position()
    if rt.magnitude(current_x - last_position_x, current_y - last_position_y) > 1 then
        elapsed = elapsed + delta
        while elapsed > delta do
            elapsed = elapsed - delta
            table.insert(history, 1, current_y)
            table.insert(history, 1, current_x)

            table.remove(history, #history)
            table.remove(history, #history)
        end
        last_position_x, last_position_y = current_x, current_y
        tail_spline = rt.Spline(history)
    end
end

love.quit = function()

end