require "include"

n_threads = 0
n_balls = 400
ball_radius = 6

gravity = 1000
world = b2.World(0, gravity)
world:set_sleeping_enabled(false)

floor_body = nil
floor_shapes = {} -- Table<Number>
floor_scissor = {} -- Table<Number>

disturbance_body = nil
disturbance_shape = {}

ball_bodies = {}
ball_meshes = {}
ball_glow_meshes = {}
ball_colors = {}
glow_ring_factor = 4
ball_friction = 0
ball_restitution = 0.05
ball_damping = 0.1 -- 1 - viscosity

ball_texture = rt.Texture("assets/sprites/why.png")

shader = rt.Shader("main_physics_blood.glsl")._native
threshold = 0.4--0.7
canvas = nil -- love.Canvas

love.load = function()
    local screen_w, screen_h = 600, 600 --1280, 720
    love.window.setMode(screen_w, screen_h, {
        msaa = 0,
        vsync = 0
    })

    canvas = rt.RenderTexture(screen_w, screen_h, 4)._native

    local center_x, center_y = 0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height()
    local world_w, world_h = 0.75 * rt.graphics.get_width(), 0.75 * rt.graphics.get_height()

    -- floor
    local floor_radius = 0.4 * world_w
    floor_body = b2.Body(world, b2.BodyType.STATIC, center_x, center_y)
    local floor_shapes = {}

    local top_right_x, top_right_y = 0.5 * world_w, -0.5 * world_h
    local bottom_right_x, bottom_right_y = 0.5 * world_w, 0.5 * world_h
    local bottom_left_x, bottom_left_y = -0.5 * world_w, 0.5 * world_h
    local top_left_x, top_left_y = -0.5 * world_w, -0.5 * world_h
    local floor_top = b2.SegmentShape(floor_body, b2.Segment(top_left_x, top_left_y, top_right_x, top_right_y))
    local floor_right = b2.SegmentShape(floor_body, b2.Segment(top_right_x, top_right_y, bottom_right_x, bottom_right_y))
    local floor_bottom = b2.SegmentShape(floor_body, b2.Segment(bottom_right_x, bottom_right_y, bottom_left_x, bottom_left_y))
    local floor_left = b2.SegmentShape(floor_body, b2.Segment(bottom_left_x, bottom_left_y, top_left_x, top_left_y))

    floor = {
        top_left_x, top_left_y, top_right_x, top_right_y,
        top_right_x, top_right_y, bottom_right_x, bottom_right_y,
        bottom_right_x, bottom_right_y, bottom_left_x, bottom_left_y,
        bottom_left_x, bottom_left_y, top_left_x, top_left_y
    }

    local floor_width = 2
    floor_scissor = {
        center_x + top_left_x + floor_width,
        center_y + top_left_y + floor_width,
        top_right_x - top_left_x - 2 * floor_width,
        bottom_left_y - top_left_y - 2 * floor_width
    }

    -- balls
    local left_x, right_x = center_x + top_left_x, center_x + top_right_x
    local top_y, bottom_y = center_y + top_left_y, center_y + bottom_right_y
    for i = 1, n_balls do
        local radius_fraction = rt.random.number(0, 1)
        local radius = 0.8 * ball_radius + radius_fraction * ball_radius
        local x = rt.random.number(left_x + radius, right_x - radius)
        local y = rt.random.number(top_y + radius, bottom_y - radius)
        local body = b2.Body(world, b2.BodyType.DYNAMIC, x, y)
        local shape = b2.CircleShape(body, b2.Circle(radius))

        body:set_is_bullet(true)
        body:set_linear_damping(ball_damping)
        body:set_rotation_fixed(false)
        shape:set_restitution(ball_restitution)
        shape:set_friction(ball_friction)

        body:set_angle(rt.random.number(0, 2 * math.pi))
        table.insert(ball_bodies, body)

        local r, g, b, a = rt.color_unpack(rt.lcha_to_rgba(rt.LCHA(
            0.8,
            1,
            radius_fraction,
            1
        )))

        local ball_data = {
            {0, 0, 0.5, 0.5, 1, 1, 1, 0.5}
        }

        local glow_data = {
            {0, 0, 0.5, 0.5, 1, 1, 1, 1}
        }

        local n_outer_vertices = 64
        local step = 2 * math.pi / n_outer_vertices
        local vertex_map = {}

        local texture_path = rt.Path(
            0, 0,
            0, 1,
            1, 1,
            1, 0
        )

        local vertex_i = 2
        for angle = 0, 2 * math.pi, step do

            local current_radius = radius
            local cx, cy = math.cos(angle) * current_radius, math.sin(angle) * current_radius
            table.insert(ball_data, {
                cx, cy,
                (cx / (2 * current_radius)) + 0.5,
                (cy / (2 * current_radius)) + 0.5,
                1, 1, 1, 0
            })

            current_radius = radius * glow_ring_factor
            cx, cy = math.cos(angle) * current_radius, math.sin(angle) * current_radius
            table.insert(glow_data, {
                cx, cy,
                (cx / (2 * current_radius)) + 0.5,
                (cy / (2 * current_radius)) + 0.5,
                1, 1, 1, 0
            })

            if vertex_i < n_outer_vertices + 1 then
                for j in range(1, vertex_i, vertex_i + 1) do
                    table.insert(vertex_map, j)
                end
            end
            vertex_i = vertex_i + 1
        end
        for j in range(1, n_outer_vertices + 1, 2) do table.insert(vertex_map, j) end

        local ball_mesh = rt.VertexShape(ball_data, rt.MeshDrawMode.TRIANGLES)
        local glow_mesh = rt.VertexShape(glow_data, rt.MeshDrawMode.TRIANGLES)

        for mesh in range(ball_mesh, glow_mesh) do
            mesh._native:setVertexMap(vertex_map)
            mesh:set_texture(ball_texture)
        end

        table.insert(ball_meshes, ball_mesh._native)
        table.insert(ball_glow_meshes, glow_mesh._native)
        table.insert(ball_colors, {r, g, b, a})
    end

    -- disturbance
    do
        disturbance_body = b2.Body(world, b2.BodyType.KINEMATIC, center_x, center_y)
        local r = ball_radius * 10
        disturbance_shape = {
            -r, -0.15 * r,
            r, -0.15 * r,
            r, 0.15 * r,
            -r, 0.15 * r
        }
        local disturbance_shape = b2.PolygonShape(disturbance_body, b2.Polygon(table.unpack(disturbance_shape)))
    end
end

love.draw = function()
    local lg = love.graphics
    local unpack = table.unpack

    lg.setColor(1, 1, 1, 1)
    lg.print(love.timer.getFPS(), 5, 5)

    lg.setCanvas(canvas)
    lg.clear(0, 0, 0, 0)
    rt.graphics.set_blend_mode(rt.BlendMode.NORMAL, rt.BlendMode.ADD)
    for i = 1, n_balls do
        local x, y = ball_bodies[i]:get_centroid()
        local angle = ball_bodies[i]:get_angle()

        --lg.setColor(unpack(ball_colors[i]))
        lg.draw(ball_glow_meshes[i], x, y, angle)
        lg.draw(ball_meshes[i], x, y, angle)
    end
    lg.setBlendMode("alpha")
    lg.setCanvas(nil)

    lg.setScissor(unpack(floor_scissor))
    lg.setShader(shader)
    shader:send("threshold", threshold)
    lg.setColor(1, 1, 1, 1)
    lg.draw(canvas)
    lg.setShader(nil)
    lg.setScissor(0, 0, lg.getDimensions())

    lg.push()
    lg.setColor(1, 0, 1, 1)
    local x, y = disturbance_body:get_centroid()
    lg.translate(x, y)
    lg.polygon("fill", unpack(disturbance_shape))
    lg.pop()

    lg.push()
    lg.setColor(1, 1, 1, 1)
    lg.setLineWidth(1)
    lg.translate(floor_body:get_centroid())
    lg.line(floor)
    lg.pop()
end

do
    local n_called = 0
    local _callback = function(shape_a, shape_b)
        local body_a = shape_a:get_body()
        local body_b = shape_b:get_body()

        local a_x, a_y = body_a:get_centroid()
        local b_x, b_y = body_b:get_centroid()
        local dx = b_x - a_x
        local dy = b_y - a_y
        local distance = math.sqrt(dx * dx + dy * dy)

        local surface_tension_coefficient = 0.25
        local surface_tension_force_magnitude = surface_tension_coefficient * distance

        local force_x = surface_tension_force_magnitude * (dx / (5 * distance))
        local force_y = surface_tension_force_magnitude * (dy / (5 * distance))

        body_a:apply_force(force_x, force_y)
        body_b:apply_force(-force_x, -force_y)

        n_called = n_called + 1
    end

    love.update = function(delta)
        --if love.keyboard.isDown("space") then
            world:step(math.min(delta, 1 / 60))
        --end

        -- Update disturbance
        local mouse_x, mouse_y = love.mouse.getPosition()
        local current_x, current_y = disturbance_body:get_centroid()
        local distance = rt.distance(current_x, current_y, mouse_x, mouse_y)
        local disturbance_strength = 10
        disturbance_body:set_linear_velocity((mouse_x - current_x) * disturbance_strength, (mouse_y - current_y) * disturbance_strength)

        n_called = 0
        --world:get_contact_events(nil, _callback, nil)
    end
end

love.keypressed = function(key)
    if key == "up" then
        threshold = threshold + 0.1
        --world:set_gravity(0, -gravity)
    elseif key == "right" then
        --world:set_gravity(gravity, 0)
    elseif key == "down" then
        threshold = threshold - 0.1
        --world:set_gravity(0, gravity)
    elseif key == "left" then
        --world:set_gravity(-gravity, 0)
    end
    dbg(threshold)
end
