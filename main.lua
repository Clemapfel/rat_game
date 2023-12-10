require "include"

rt.add_scene("debug")

if meta.is_nil(env.action_spritesheet) then
    env.action_spritesheet = rt.Spritesheet("assets/sprites", "orbs")
end

local sprites = {}
local n = 10
local step = 360 / n
local center = math3d.vec3(0, 0, 0)
local radius = 0.5

for sprite_i = 1, n do
    local sprite = rt.Sprite(env.action_spritesheet, "dusk")
    sprite:realize()
    sprite._shape:resize(-0.1, -0.1, 0.2, 0.2)
    sprite._shape:set_color(rt.HSVA(sprite_i / n, 1,1, 1))
    --sprite._shape:set_texture(nil)
    table.insert(sprites, sprite)

    local transform = math3d.mat4()
    local angle = rt.degrees(step * sprite_i):as_radians()
    angle = angle + 0.5 * step
    transform:translate(transform, math3d.vec3(center.x + math.cos(angle) * radius, 0, center.y + math.sin(angle) * radius))
    transform:translate(transform, math3d.vec3(0, 0, radius))
    for vertex_i = 1, sprite._shape:get_n_vertices() do
        local pos = math3d.vec3(sprite._shape:get_vertex_position(vertex_i))
        pos = transform * pos
        sprite._shape:set_vertex_position(vertex_i, pos.x, pos.y, pos.z)
    end

    sprite_i = sprite_i + 1
end

--rt.current_scene:set_child(tooltip)

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then

    elseif which == rt.InputButton.B then

    elseif which == rt.InputButton.X then

    elseif which == rt.InputButton.Y then

    elseif which == rt.InputButton.UP then
        rt.Renderer:move_camera(0, speed, 0)
    elseif which == rt.InputButton.DOWN then
        rt.Renderer:move_camera(0, -speed, 0)
    elseif which == rt.InputButton.RIGHT then
        rt.Renderer:move_camera(speed, 0, 0)
    elseif which == rt.InputButton.LEFT then
        rt.Renderer:move_camera(-speed, 0, 0)
    elseif which == rt.InputButton.R then
        rt.Renderer:move_camera(0, 0, speed)
    elseif which == rt.InputButton.L then
        rt.Renderer:move_camera(0, 0, -speed)
    end

    if which == rt.InputButton.A then
        rt.Renderer:reset_camera()
    end
end)

function love.load()
    rt.current_scene:realize()
end

local mesh = love.graphics.newMesh(rt.VertexFormat, {
    {0, 0, 0,  0, 0, 1, 1, 1, 1}
}, "points")

function love.draw()

    rt.Renderer:draw_3d(function()
        love.graphics.clear(1, 0, 1, 1)
        for _, sprite in pairs(sprites) do
            sprite:draw()
        end
    end)
    rt.Renderer:draw()

    -- scene rendering
    --rt.current_scene:draw()

    love.graphics.draw(mesh)
end