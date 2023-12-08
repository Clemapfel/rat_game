require "include"

rt._3d = {}

rt._3d.shader = love.graphics.newShader([[
uniform mat4 model_matrix;
uniform mat4 view_matrix;
uniform mat4 projection_matrix;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return projection_matrix * view_matrix * model_matrix * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords);
	return color * pixel;
}
#endif
]])

rt._3d.depth_buffer = {
    color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
    depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"}),
}
rt._3d.depth_buffer.canvas = {rt._3d.depth_buffer.color, depthstencil = rt._3d.depth_buffer.depth}

local vertices = {}
local lower, upper = rt.degrees(0):as_radians(), rt.degrees(360):as_radians()
local n_steps = 19
local step = 2 * math.pi / n_steps

local sum = math3d.vec3(0, 0, 0)
for x = lower, upper, step do
    for y = lower, upper, step do
        for z = lower, upper, step do
            local m = math3d.mat4()
            m:rotate(m, x, math3d.vec3.unit_x)
            m:rotate(m, y, math3d.vec3.unit_y)
            m:rotate(m, z, math3d.vec3.unit_z)

            local point = math3d.vec3(1, 1, 1)
            point:rotate(point, z, math3d.vec3.unit_z)
            point:rotate(point, x, math3d.vec3.unit_x)
            point:rotate(point, y, math3d.vec3.unit_y)

            point = m * point

            table.insert(vertices, {
                point.x, point.y, point.z
            })
        end
    end
end

println(sizeof(vertices))

mesh_shape = rt.VertexShape(vertices)
mesh_shape:set_draw_mode(rt.MeshDrawMode.POINTS)
local n = mesh_shape:get_n_vertices()
for i = 1, n do
    local x, y, z = mesh_shape:get_vertex_position(i)
    x = x - sum.x / n
    y = y - sum.y / n
    z = z - sum.z / n
    mesh_shape:set_vertex_position(i, x, y, z)
    mesh_shape:set_vertex_color(i, rt.HSVA(i / n, 1, 1, 1));
end

mesh = mesh_shape._native

rt._3d.camera = {
    position = math3d.vec3(0, 0, 0),
    rotation = math3d.vec2(0, 0),

    direction = nil,
    right     = nil,
    up        = nil,
}

rt._3d.camera.direction = math3d.vec3(
    math.cos(rt._3d.camera.rotation.y) * math.sin(rt._3d.camera.rotation.x),
    math.sin(rt._3d.camera.rotation.y),
    math.cos(rt._3d.camera.rotation.y) * math.cos(rt._3d.camera.rotation.x)
)

rt._3d.camera.right = math3d.vec3(
    math.sin(rt._3d.camera.rotation.x - math.pi/2),
    0,
    math.cos(rt._3d.camera.rotation.x - math.pi/2)
)

rt._3d.camera.forward = math3d.vec3(
    math.sin(rt._3d.camera.rotation.x + math.pi),
    0,
    math.cos(rt._3d.camera.rotation.x + math.pi)
)

rt._3d.camera.up = math3d.vec3.cross(rt._3d.camera.right, rt._3d.camera.direction)

local view_matrix = math3d.mat4()
local model_matrix = math3d.mat4()

function love.update(dt)

    local movementVector = math3d.vec3()
    local camera = rt._3d.camera

    if love.keyboard.isDown("w") then
        movementVector = movementVector - camera.forward
    end

    if love.keyboard.isDown("s") then
        movementVector = movementVector + camera.forward
    end

    rt._3d.camera.position = rt._3d.camera.position + movementVector * 0.1

    if love.keyboard.isDown("up") then
        model_matrix:translate(model_matrix, math3d.vec3(0, 1, 0))
    end

    if love.keyboard.isDown("down") then
        model_matrix:translate(model_matrix, math3d.vec3(0, -1, 0))
    end

    local rotation_offset = rt.degrees(0.5 * dt):as_radians();
    if love.keyboard.isDown("left") then
        camera.rotation.x = camera.rotation.x - rotation_offset
        model_matrix:rotate(model_matrix, camera.rotation.x, math3d.vec3.unit_y)
    end
    if love.keyboard.isDown("right") then
        camera.rotation.y = camera.rotation.y + rotation_offset
        model_matrix:rotate(model_matrix, camera.rotation.y, math3d.vec3.unit_y)
    end

    model_matrix:rotate(model_matrix, rt.degrees(0.1):as_radians(), math3d.vec3.unit_y)


    view_matrix = view_matrix:identity()
    view_matrix:translate(view_matrix, camera.position + camera.forward)
    view_matrix:look_at(camera.position, math3d.vec3(0, 0, 0), camera.up)
end

function love.draw()
    
rt._3d.shader:send("view_matrix",       "column", view_matrix)
rt._3d.shader:send("projection_matrix", "column", math3d.mat4.from_perspective(100, love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 1000))

love.graphics.setShader(rt._3d.shader)
love.graphics.setColor(1, 1, 1)
love.graphics.setDepthMode("lequal", true)
love.graphics.setCanvas(rt._3d.depth_buffer.canvas)
love.graphics.clear(0, 0, 0, 0, true, 1)
love.graphics.setMeshCullMode("none")

love.graphics.setPointSize(3)

rt._3d.shader:send("model_matrix", "column", model_matrix)
love.graphics.draw(mesh)

love.graphics.setMeshCullMode("none")
love.graphics.setShader()
love.graphics.setDepthMode()
love.graphics.setCanvas()

love.graphics.draw(rt._3d.depth_buffer.color)

end

function love.keypressed(key)
    if key == "q" then
        love.event.quit()
    elseif key == "t" then
        love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.getRelativeMode() then
        local rotationVector = math3d.vec2(-dx, dy)
        rt._3d.camera.rotation = rt._3d.camera.rotation + rotationVector / 80
    end
end
