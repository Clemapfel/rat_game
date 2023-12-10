--- @class
rt.Renderer = {}

--- shader source
rt.Renderer._shader_source = [[
uniform mat4 view_matrix;
uniform mat4 projection_matrix;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return projection_matrix * view_matrix * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    return pixel * color;
}
#endif
]]

-- 3d depth buffers
rt.Renderer.depth_buffer = {
    color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
    depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"}),
}
rt.Renderer.depth_buffer.canvas = {rt.Renderer.depth_buffer.color, depthstencil = rt.Renderer.depth_buffer.depth}

-- 2d render canvas, this is what regular love will be rendered to
rt.Renderer._resolution = { love.graphics.getWidth(), love.graphics.getHeight() }
rt.Renderer._2d_canvas = rt.RenderTexture(love.graphics.getWidth(), love.graphics.getHeight())
rt.Renderer._2d_shape = rt.VertexRectangle(0 - 0.5 * love.graphics.getWidth(), 0 - 0.5 * love.graphics.getHeight(), love.graphics.getWidth(), love.graphics.getHeight())
rt.Renderer._2d_shape:set_texture(rt.Renderer._2d_canvas)

-- camera
rt.Renderer.camera = {
    position = math3d.vec3(0, 0, 0.84),
    rotation = math3d.vec2(0, 0),

    direction = nil,
    right     = nil,
    up        = nil,
}

rt.Renderer.camera.direction = math3d.vec3(
    math.cos(rt.Renderer.camera.rotation.y) * math.sin(rt.Renderer.camera.rotation.x),
    math.sin(rt.Renderer.camera.rotation.y),
    math.cos(rt.Renderer.camera.rotation.y) * math.cos(rt.Renderer.camera.rotation.x)
)

rt.Renderer.camera.right = math3d.vec3(
    math.sin(rt.Renderer.camera.rotation.x - math.pi/2),
    0,
    math.cos(rt.Renderer.camera.rotation.x - math.pi/2)
)

rt.Renderer.camera.forward = math3d.vec3(
    math.sin(rt.Renderer.camera.rotation.x + math.pi),
    0,
    math.cos(rt.Renderer.camera.rotation.x + math.pi)
)

rt.Renderer.camera.up = math3d.vec3.cross(rt.Renderer.camera.right, rt.Renderer.camera.direction)

-- transforms

rt.Renderer.view_matrix = math3d.mat4()
rt.Renderer.projection_matrix =math3d.mat4.from_perspective(
    100,
    love.graphics.getWidth() / love.graphics.getHeight(),
    0.1,
    1000
)

--- @brief
function rt.Renderer:_update_view_matrix(_)
    local camera = rt.Renderer.camera
    rt.Renderer.view_matrix = view_matrix:identity()
    rt.Renderer.view_matrix:translate(view_matrix, camera.position + camera.forward)
    rt.Renderer.view_matrix:look_at(camera.position, camera.position + camera.forward, camera.up)
end

--- @brief update size
function rt.Renderer:set_resolution(_, w, h)
    rt.Renderer._resolution = { w, h }

    rt.Renderer.depth_buffer = {
        color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
        depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"}),
    }
    rt.Renderer.depth_buffer.canvas = {rt.Renderer.depth_buffer.color, depthstencil = rt.Renderer.depth_buffer.depth}

    rt.Renderer._2d_canvas = rt.RenderTexture(love.graphics.getWidth(), love.graphics.getHeight())
    rt.Renderer._2d_shape = rt.VertexRectangle(0 - 0.5 * w, 0 - 0.5 * h, w, h)
    rt.Renderer.projection_matrix =math3d.mat4.from_perspective(100, w / h, 0.1, 1000)
end

--- @brief move camera in 3d dimensions
--- @param x
--- @param y
--- @param z
function rt.Renderer:move_camera(_, x, y, z)
    local translate = math3d.mat4()
    translate:translate(translate, math3d.vec3(x, y, z))
    rt.Renderer.position = translate * rt.Renderer.camera.position
end

--- @brief reset camera
function rt.Renderer:reset_camera(_)
    rt.Renderer.camera.position = math3d.vec3(0, 0, 0.84)
    rt.Renderer.camera.rotation = math3d.vec2(0, 0)
end

--- @brief render to 2d canvas in 3d space
function rt.Renderer:bind_render_2d(self, object)
    love.graphics.setShader()
    self._2d_canvas:bind_as_render_target()
end

--- @brief render 3d vertex shape in 3d space
function rt.Renderer:bind_render_3d(self, object)
    love.graphics.reset()
    love.graphics.setCanvas(self.depth_buffer.canvas)
    love.graphics.setShader(self.shader)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("none")

    self.shader:send("view_matrix",       "column", self.view_matrix)
    self.shader:send("projection_matrix", "column", self.projection_matrix)
end

--- @brief actually draw scene
function rt.Renderer:flush(self)
    love.graphics.reset()
    love.graphics.setShader()
    love.graphics.setDepthMode()
    love.graphics.setCanvas()

    love.graphics.draw(self.depth_buffer.color)
end