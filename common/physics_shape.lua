--- @class rt.ShapeType
rt.PhysicsShapeType = meta.new_enum({
    RECTANGLE = 1,
    POLYGON = 1,
    CIRCLE = 2,
    LINE = 3,
    LINE_SEGMENTS = 4,
})

--- @class rt.PhysicsShape
--- @param type rt.ShapeType
--- @varargs local_coordinates
rt.PhysicsShape = meta.new_type("PhysicsShape", function(type, ...)
    local out = meta.new(rt.PhysicsShape, {
        _native = {},
        _type = type
    })

    local n_varargs = _G._select('#', ...)
    if type == rt.PhysicsShapeType.RECTANGLE then
        assert(n_varargs == 4)
        local x, y, width, height, angle = ...
        out._native = love.physics.newRectangleShape(x, y, width, height, angle)
    elseif type == rt.PhysicsShapeType.CIRCLE then
        assert(n_varargs == 3)
        local x, y, radius = ...
        out._native = love.physics.newCircleShape(x, y, radius)
    elseif type == rt.PhysicsShapeType.LINE then
        assert(n_varargs == 4)
        local ax, ay, bx, by = ...
        out._native = love.physics.newEdgeShape(ax, ay, bx, by)
    elseif type == rt.PhysicsShapeType.LINE_SEGMENTS then
        assert(n_varargs % 2 == 0 and n_varargs >= 4)
        out._native = love.physics.newChainShape(false, ...)
    elseif type == rt.PhysicsShapeType.POLYGON then
        assert(n_varargs % 2 == 0 and n_varargs >= 6)
        out._native = love.physics.newPolygonShape(...)
    end
    return out
end)

--- @brief
--- @param shape love.physics.Shape
--- @param body_x Number
--- @param body_y Number
function rt.PhysicsShape._draw(shape, body_x, body_y)

    love.graphics.push()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)

    local type = shape:type()
    if type == "PolygonShape" then
        local local_points = {shape:getPoints()}
        for i = 1, #local_points, 2 do
            local_points[i+0] = local_points[i+0] + body_x
            local_points[i+1] = local_points[i+1] + body_y
        end
        love.graphics.polygon("fill", table.unpack(local_points))
    elseif type == "CircleShape" then
        local x, y = shape:getPoint()
        x = x + body_x
        y = y + body_y
        local radius = shape:getRadius()
        love.graphics.circle("fill", x, y, radius)
    elseif type == "EdgeShape" then
        local ax, ay, bx, by = shape:getPoints()
        ax = ax + body_x
        ay = ay + body_y
        bx = bx + body_x
        by = by + body_y
        love.graphics.line(ax, ay, bx, by)
    elseif type == "ChainShape" then
        local local_points = {shape:getPoints()}
        for i = 1, #local_points, 2 do
            local_points[i+0] = local_points[i+0] + body_x
            local_points[i+1] = local_points[i+1] + body_y
        end
        love.graphics.lines(table.unpack(local_points))
    end

    love.graphics.pop()
end