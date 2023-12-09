require "include"

--[[
function connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end
try_catch(connect_emmy_lua_debugger)
io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately
]]--

-- #############################

--rt.add_scene("debug")



shader_3d = love.graphics.newShader([[
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

local depth_buffer = {
    color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
    depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"})
}
depth_buffer.canvas = {depth_buffer.color, depthstencil = depth_buffer.depth}

vertex_format_3d = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord","float", 2},
    {"VertexColor", "byte", 4},
}

mesh = love.graphics.newMesh(vertex_format_3d, {

    -- Front
    {-1, -1, 1, 0, 1, 1,    1,    1,    1},
    { 1, -1, 1, 1, 1, 1,    1,    1,    1},
    {-1,  1, 1, 0, 0, 1,    1,    1,    1},
    { 1,  1, 1, 1, 0, 1,    1,    1,    1},

    -- Back
    { 1, -1, -1, 0, 1, 1,    1,    1,    1},
    {-1, -1, -1, 1, 1, 1,    1,    1,    1},
    { 1,  1, -1, 0, 0, 1,    1,    1,    1},
    {-1,  1, -1, 1, 0, 1,    1,    1,    1},

    -- Left
    {-1, -1, -1, 0, 1, 1,    1,    1,    1},
    {-1, -1,  1, 1, 1, 1,    1,    1,    1},
    {-1,  1, -1, 0, 0, 1,    1,    1,    1},
    {-1,  1, 1,  1, 0, 1,    1,    1,    1},

    -- Right
    { 1, -1,  1,  0, 1, 1,    1,    1,    1},
    { 1, -1, -1,  1, 1, 1,    1,    1,    1},
    { 1,  1,  1,  0, 0, 1,    1,    1,    1},
    { 1,  1, -1,  1, 0, 1,    1,    1,    1},

    -- Top
    {-1, -1, -1,  0, 1, 1,    1,    1,    1},
    { 1, -1, -1,  1, 1, 1,    1,    1,    1},
    {-1, -1,  1,  0, 0, 1,    1,    1,    1},
    { 1, -1,  1,  1, 0, 1,    1,    1,    1},

    -- Bottom
    { 1, 1, -1, 0, 1, 1,    1,    1,    1},
    {-1, 1, -1, 1, 1, 1,    1,    1,    1},
    { 1, 1,  1, 0, 0, 1,    1,    1,    1},
    {-1, 1,  1, 1, 0, 1,    1,    1,    1},
}, "triangles")

mesh:setVertexMap({
    1,  3,  2,  2,  3,  4,
    5,  7,  6,  6,  7,  8,
    9, 11, 10, 10, 11, 12,
    13, 15, 14, 14, 15, 16,
    17, 19, 18, 18, 19, 20,
    21, 23, 22, 22, 23, 24,
})

camera = {
    position = math3d.vec3(0, 0, -10),
    rotation = math3d.vec2(0, 0)
}

camera.direction = math3d.vec3(
    math.cos(camera.rotation.y) * math.sin(camera.rotation.x),
    math.sin(camera.rotation.y),
    math.cos(camera.rotation.y) * math.cos(camera.rotation.x)
)

camera.right = math3d.vec3(
    math.sin(camera.rotation.x - math.pi/2),
    0,
    math.cos(camera.rotation.x - math.pi/2)
)

camera.forward = math3d.vec3(
    math.sin(camera.rotation.x + math.pi),
    0,
    math.cos(camera.rotation.x + math.pi)
)

camera.up = math3d.vec3.cross(camera.right, camera.direction)
camera.position = math3d.vec3(0, 0, 0)

perspective_matrix = math3d.mat4.from_perspective(
    75,  -- field of view
    love.graphics.getWidth() / love.graphics.getHeight(), -- aspect ratio
    0.1, -- near plane
    1000 -- far plane
)

view_matrix = math3d.mat4()

local model_matrix_01 = math3d.mat4.identity()
model_matrix_01:translate(model_matrix_01, math3d.vec3(5, 0, 0))

local model_matrix_02 = math3d.mat4.identity()
model_matrix_02:translate(model_matrix_02, math3d.vec3(5, 0, 2))

function draw_3d()
    view_matrix.look_at(view_matrix, camera.position, camera.position + camera.direction, camera.up)
    view_matrix:translate(view_matrix, camera.position)
    view_matrix:rotate(view_matrix, camera.rotation.y, math3d.vec3.unit_x)
    view_matrix:rotate(view_matrix, camera.rotation.x, math3d.vec3.unit_y)

    shader_3d:send("view_matrix", "column", view_matrix)
    shader_3d:send("projection_matrix", "column", perspective_matrix)

    love.graphics.setShader(shader_3d)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setDepthMode("always", true)
    love.graphics.setCanvas({
        depth_buffer.color,
        stencil = true,
        depth = true,
        depthstencil = depth_buffer.depth
    })

    love.graphics.clear(1, 0, 1, 1, true, 1)
    love.graphics.setMeshCullMode("back")

    shader_3d:send("model_matrix", "column", model_matrix_01)
    love.graphics.draw(mesh)

    shader_3d:send("model_matrix", "column", model_matrix_02)
    love.graphics.draw(mesh)

    love.graphics.line(0, 0, 500, 500)

    love.graphics.setShader()
    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    love.graphics.draw(depth_buffer.color)
end

-- #############################

--- @brief startup
function love.load()

    --rt.current_scene:realize()
end

--- @brief update tick
function love.update()
    --rt.current_scene:update(love.timer.getDelta())
    
end

--- @brief draw step
function love.draw()

    --rt.current_scene:draw()
    draw_3d()
    
    function show_fps()
        local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
        local w, h = text:getWidth(), text:getHeight()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(text, love.graphics.getWidth() - w, 0)
    end
    show_fps()
end

--- @brief shutdown
function love.quit()
    --rt.Palette:export("palette.png")
end

::exit::