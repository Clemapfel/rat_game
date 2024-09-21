require "include"

world = b2.World(0, 200)

bodies = {}
shapes = {}
joints = {}
chain_body = nil
player = nil

love.load = function()
    local margin_x, margin_y = 0.01 * rt.graphics.get_width(), 0.01 * rt.graphics.get_height()
    local floor_body = b2.Body(world, b2.BodyType.STATIC, 0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height())
    local floor_xr, floor_yr = 0.5 * rt.graphics.get_width() - 0.5 * margin_x, 0.5 * rt.graphics.get_height() - 0.5 * margin_y
    screen_w, screen_h = rt.graphics.get_width(), rt.graphics.get_height()

    table.insert(shapes, b2.PolygonShape(floor_body, b2.Rectangle(
        screen_w, margin_y,
        0, -floor_yr + 0.5 * margin_y
    )))

    table.insert(shapes, b2.PolygonShape(floor_body, b2.Rectangle(
        margin_x, screen_h,
        floor_xr - 0.5 * margin_x, 0
    )))

    table.insert(shapes, b2.PolygonShape(floor_body, b2.Rectangle(
        screen_w, margin_y,
        0, floor_yr - 0.5 * margin_y
    )))

    table.insert(shapes, b2.PolygonShape(floor_body, b2.Rectangle(
        margin_x, screen_h,
        -floor_xr + 0.5 * margin_x, 0
    )))

    local player_radius = 25
    player = b2.Body(world, b2.BodyType.DYNAMIC, 0.5 * rt.graphics.get_width(), rt.graphics.get_height() * 0.5)
    player_shape = b2.CapsuleShape(player, b2.Capsule(0, -0.5 * player_radius, 0, 0.5 * player_radius, player_radius))

    local rope_x, rope_y = 0.5 * rt.graphics.get_width(), 8 * margin_x
    local rope_length = (rt.graphics.get_height() - 8 * margin_x) * 0.75
    local n_segments = 40

    local segment_length = rope_length / n_segments
    local rope_width = 0.01 * rt.graphics.get_width()

    local current_y = rope_y
    local previous_body = nil
    local previous_body_bottom_x, previous_body_bottom_y = nil, nil

    local first_body
    for i = 1, n_segments do
        local body = b2.Body(world, b2.BodyType.DYNAMIC, rope_x, current_y)

        if i == 1 then
            chain_body = body
        end

        local radius = rope_width / 2

        local top_x, top_y = 0, -0.5 * segment_length + radius
        local bottom_x, bottom_y = 0, 0.5 * segment_length - radius

        --[[
        local shape = b2.CapsuleShape(body, b2.Capsule(
            top_x, top_y,
            bottom_x, bottom_y,
            radius
        ))
        ]]--

        local shape = b2.CircleShape(body, b2.Circle(2 * radius))

        if i == 1 then
            local joint = b2.DistanceJoint(world, floor_body, body, 10, 0, -0.5 * screen_h)
            --local joint = b2.DistanceJoint(world, player, body, 10, 0, 0.5 * player_radius, 0, 0)
            table.insert(joints, joint)
        else
            --[[
            local joint = b2.WeldJoint(world, previous_body, body,
                previous_body_bottom_x, previous_body_bottom_y,
                top_x, top_y,
                true,
                0, 0
            )
            ]]--

            local join = b2.DistanceJoint(world, previous_body, body, 10, previous_body_bottom_x, previous_body_bottom_y, top_x, top_y)
            table.insert(joints, joint)
        end


        table.insert(bodies, body)
        table.insert(shapes, shape)
        current_y = current_y + segment_length
        previous_body = body
        previous_body_bottom_x, previous_body_bottom_y = bottom_x, bottom_y
    end


    --table.insert(joints, b2.WeldJoint(world, player, chain_body, 0, -0.5 * player_radius, 0, 0, true))
end

love.keypressed = function(which)
    if which == "space" then
        world:raycast(0.5 * screen_w, 0.5 * screen_h, 0.5 * screen_w, screen_h)
    end
end

love.update = function(delta)
    world:step(delta, 16)

    local mouse_x, mouse_y = love.mouse.getPosition()
    local body_x, body_y = player:get_centroid()
    local magnitude = rt.distance(mouse_x, mouse_y, body_x, body_y)
    player:set_linear_velocity((mouse_x - body_x) * magnitude, (mouse_y - body_y) * magnitude)
end

love.draw = function()
    for shape in values(shapes) do
        shape:draw()
    end

    for joint in values(joints) do
        joint:draw()
    end

    player:draw()
end