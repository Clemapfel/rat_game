require "include"

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
mesh = polyhedron(3)

rt.add_scene("debug")

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)
    local speed = 0.1
    if which == rt.InputButton.UP then
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

function love.draw()
    local background_color = rt.Palette.PURPLE_2

    rt.Renderer:draw_2d(function()
        love.graphics.setLineWidth(10)
        love.graphics.rectangle("line", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.print("text abada", 200, 200)
    end)

    rt.Renderer:draw_3d(function()
        mesh:draw()
    end)

    rt.Renderer:flush()
end