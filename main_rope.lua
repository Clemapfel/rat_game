require "include"

world = b2.World(0, 100)

bodies = {}
shapes = {}
joints = {}

love.load = function()
    local rope_x, rope_y = 0.5 * rt.graphics.get_width(), 0.3 * rt.graphics.get_height()
    local rope_length = 0.75 * rt.graphics.get_height()
    local n_segments = 4

    local segment_length = rope_length / n_segments
    local rope_width = 0.05 * rt.graphics.get_width()

    local current_y = rope_y
    for i = 1, n_segments do
        local body = b2.Body(world, b2.BodyType.DYNAMIC, rope_x + current_y / 2, current_y - 0.5 * segment_length)

        local radius = rope_width / 2

        local shape = b2.CapsuleShape(body, b2.Capsule(
            0, -0.5 * segment_length + 0.5 * radius,
            0, 0.5 * segment_length - 0.5 * radius,
            radius
        ))

        table.insert(bodies, body)
        table.insert(shapes, shape)
        current_y = current_y + segment_length

        body:apply_linear_impulse(1, 0)
    end

    local margin_x, margin_y = 0.01 * rt.graphics.get_width(), 0.01 * rt.graphics.get_height()
    local floor_body = b2.Body(world, b2.BodyType.STATIC, 0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height())

    local floor_xr, floor_yr = 0.5 * rt.graphics.get_width() - 0.5 * margin_x, 0.5 * rt.graphics.get_height() - 0.5 * margin_y
    local screen_w, screen_h = rt.graphics.get_width(), rt.graphics.get_height()

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
end

love.update = function(delta)
    world:step(delta, 4)
end

love.draw = function()
    for shape in values(shapes) do
        shape:draw()
    end

    for joint in values(joints) do
        joint:draw()
    end
end