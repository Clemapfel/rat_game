--- @class Renderer allows rendering in 3d
rt.Renderer = {}

--- shader
rt.Renderer.shader_source = [[
uniform highp mat4 view_matrix;
uniform highp mat4 projection_matrix;

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

rt.Renderer.shader = love.graphics.newShader(rt.Renderer.shader_source)

-- 3d depth buffers
rt.Renderer.depth_buffer = {
    color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
    depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"}),
}
rt.Renderer.depth_buffer.canvas = {rt.Renderer.depth_buffer.color, depthstencil = rt.Renderer.depth_buffer.depth}

-- 2d render canvas, this is what regular love will be rendered to
rt.Renderer._resolution = { love.graphics.getWidth(), love.graphics.getHeight() }
rt.Renderer._2d_canvas = (function()
    local out = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {
        msaa = 8
    })
    out:setFilter(rt.TextureScaleMode.NEAREST)
    out:setWrap(rt.TextureWrapMode.REPEAT)
    return out
end)()


rt.Renderer._2d_shape = (function()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local canvas_h = 1
    local canvas_w = w / h * canvas_h
    return rt.VertexRectangle(0 - 0.5 * canvas_w, 0 - 0.5 * canvas_h, canvas_w, canvas_h)
end)()

rt.Renderer._2d_shape._native:setTexture(rt.Renderer._2d_canvas)

-- camera
rt.Renderer.camera = {
    position = math3d.vec3(0, 0, 0.0), -- distance what is the expression for this value?
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
    rt.Renderer.view_matrix = self.view_matrix:identity()
    rt.Renderer.view_matrix:translate(self.view_matrix, camera.position + camera.forward)
    rt.Renderer.view_matrix:look_at(camera.position, camera.position + camera.forward, camera.up)
end

--- @brief update size
function rt.Renderer:set_resolution(w, h)
    rt.Renderer._resolution = { w, h }

    rt.Renderer.depth_buffer = {
        color = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "rgba8"}),
        depth = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight(), {format = "depth24"}),
    }
    rt.Renderer.depth_buffer.canvas = {rt.Renderer.depth_buffer.color, depthstencil = rt.Renderer.depth_buffer.depth}

    rt.Renderer._2d_canvas = rt.RenderTexture(love.graphics.getWidth(), love.graphics.getHeight())
    rt.Renderer._2d_shape = rt.VertexRectangle(0 - 1, 0 - 1, w / h * 2, 2)
    rt.Renderer.projection_matrix = math3d.mat4.from_perspective(100, w / h, 0.1, 1000)
end

--- @brief move camera in 3d dimensions
--- @param x
--- @param y
--- @param z
function rt.Renderer:move_camera(x, y, z)
    local translate = math3d.mat4()
    translate:translate(translate, math3d.vec3(x, y, z))
    rt.Renderer.camera.position = translate * rt.Renderer.camera.position
    self:_update_view_matrix()
end

--- @brief reset camera
function rt.Renderer:reset_camera()
    rt.Renderer.camera.position = math3d.vec3(0, 0, 0.84)
    rt.Renderer.camera.rotation = math3d.vec2(0, 0)
    self:_update_view_matrix()
end
rt.Renderer:_update_view_matrix()

--- @brief
function rt.Renderer:render()

    local bg_color = rt.Palette.PURPLE_2

    love.graphics.setCanvas(self._2d_canvas)
    love.graphics.clear(bg_color.r, bg_color.g, bg_color.b, 1)
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.print("text abada", 200, 200)
    love.graphics.setCanvas()

    self.shader:send("view_matrix",       "column", self.view_matrix)
    self.shader:send("projection_matrix", "column", self.projection_matrix)

    love.graphics.reset()
    love.graphics.setShader(self.shader)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setCanvas(self.depth_buffer.canvas)
    love.graphics.setMeshCullMode("none")

    love.graphics.setShader(self.shader)
    love.graphics.clear(bg_color.r, bg_color.g, bg_color.b, 1)

    if not meta.is_nil(mesh) then
        mesh:draw()
    end
end

--- @brief
function rt.Renderer:draw_2d(callback)
    love.graphics.setCanvas({
        self._2d_canvas,
        stencil = true
    })
    love.graphics.clear(0, 0, 0, 0)
    callback()
    love.graphics.setCanvas()
end

--- @brief
function rt.Renderer:draw_3d(callback)

    love.graphics.setShader(rt.Renderer.shader)
    rt.Renderer.shader:send("view_matrix",       "column", self.view_matrix)
    rt.Renderer.shader:send("projection_matrix", "column", self.projection_matrix)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setCanvas(rt.Renderer.depth_buffer.canvas)
    love.graphics.setMeshCullMode("none")

    love.graphics.clear(0, 0, 0, 0)
    self._2d_shape:draw()
    callback()

    love.graphics.setMeshCullMode("none")
    love.graphics.setCanvas()
    love.graphics.setDepthMode()
    love.graphics.setShader()
end

--- @brief
function rt.Renderer:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(rt.Renderer.depth_buffer.color)
end

--- @brief _internal
function rt.test.renderer()

    function polyhedron(n_steps)
        n_steps = clamp(1, n_steps)

        local vertices = {}
        local lower, upper = rt.degrees(-180):as_radians(), rt.degrees(180):as_radians()
        local step = 2 * math.pi / n_steps
        local sum = math3d.vec3(0, 0, 0)

        for x_i = 1, n_steps do
            for z_i = 1, n_steps do
                local x = 1 * x_i * 2 * rt.degrees(180):as_radians() / n_steps
                local z = -1 * z_i * 2 * rt.degrees(180):as_radians() / n_steps

                local point = math3d.vec3.unit_y
                local rotation =
                math3d.quat.from_angle_axis(z, math3d.vec3.unit_z) *
                        math3d.quat.from_angle_axis(x, math3d.vec3.unit_x)

                point = rotation * point
                table.insert(vertices, {
                    point.x,
                    point.y,
                    point.z
                })
            end
        end

        table.sort(vertices, function(a, b)
            return a[3] > b[3]
        end)

        local vertex_order = {}
        for i = 1, sizeof(vertices) - 2 do
            table.insert(vertex_order, i)
            table.insert(vertex_order, i + 2)
            table.insert(vertex_order, i + 1)
        end

        local min, max = POSITIVE_INFINITY, NEGATIVE_INFINITY
        for _, v in pairs(vertices) do
            min = math.min(v[3], min)
            max = math.max(v[3], max)
        end

        mesh = rt.VertexShape(vertices)
        mesh:set_draw_mode(rt.MeshDrawMode.TRIANGLE_STRIP)
        mesh._native:setVertexMap(vertex_order)
        local n = mesh:get_n_vertices()
        for i = 1, n do
            local x, y, z = mesh:get_vertex_position(i)
            x = x - sum.x / n
            y = y - sum.y / n
            z = z - sum.z / n
            mesh:set_vertex_position(i, x, y, z)

            local value = (z - min) / (max - min)
            mesh:set_vertex_color(i, rt.HSVA(value, 1, 1, 1));
        end
        return mesh
    end


    if meta.is_nil(mesh) then
        mesh = polyhedron(3)
    end

    rt.Renderer:draw_2d(function()
    end)
    rt.Renderer:draw_3d(function()
        mesh:draw()
    end)
    rt.Renderer:draw()
end