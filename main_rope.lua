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
local total_w = 200
local n = 20
local w = total_w / n
local overlap = 0.1

local joint_x, joint_y
for i = 0, n do
    local collider = rt.RectangleCollider(
        world, rt.ColliderType.DYNAMIC,
        x + i * w - overlap * w, y, ternary(i == n, w * 2, w), h
    )
    collider:set_mass(0)
    --collider:set_collision_group(bit.lshift(1, i))
    table.insert(tail, collider)

    if i > 0 and i <= n then
        joint_x, joint_y = x + (i-1) * w - overlap * w + w, y + 0.5 * h
        local joint = rt.Joint(
            ternary(i == n, rt.JointType.FIXED, rt.JointType.PIVOT),
            tail[i+1], tail[i+1-1],
            joint_x, joint_y
        )
        table.insert(joints, joint)
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

spline = nil
function update_spline()
    local vertices = {}
    for body in values(tail) do
        local x, y = body:get_position()
        table.insert(vertices, x)
        table.insert(vertices, y)
    end
    --[[
    local x, y = player:get_position()
    table.insert(vertices, x)
    table.insert(vertices, y)
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

    player:draw()

    for c in values(tail) do
        c:draw()
    end

    for c in values(joints) do
        c:draw()
    end

    love.graphics.setLineWidth(5)
    local color = rt.Palette.PURPLE_1
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    spline:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    world:update(delta)
    player:update(delta)
    update_spline()
end

love.quit = function()

end