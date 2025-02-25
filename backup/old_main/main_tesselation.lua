require "include"

local ts = {}
ts.translate = function(x, y, vector)
    return x + math.cos(vector.angle) * vector.magnitude,
    y + math.sin(vector.angle) * vector.magnitude
end

ts.magnitude = function(x, y)
    return math.sqrt(x^2 + y^2)
end

ts.distance = function(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

ts.angle = function(x, y)
    return math.atan(y, x)
end

ts.normalize = function(vector)
    local magnitude = vector.magnitude
    if magnitude == 0 then
        return ts.Vector(0, 0)
    else
        local x = math.cos(vector.angle) * magnitude
        local y = math.sin(vector.angle) * magnitude
        return ts.Vector(x / magnitude, y / magnitude)
    end
end

--- ### GLOBALS ###

vertices = {}
active_vertex_i = 0
n_vertices = 0
vertex_radius = 15

love.load = function(delta)
    local center_x, center_y = 0.5 * love.graphics.getWidth(), 0.5 * love.graphics.getHeight()
    local x_radius, y_radius = 200, 100

    local origin_x, origin_y = center_x, center_y
    local w, h = 100, 100
    vertices = {}
    table.insert(vertices, {origin_x, origin_y})
    table.insert(vertices, {origin_x + w, origin_y})
    table.insert(vertices, {origin_x, origin_y + h})
    n_vertices = sizeof(vertices)
end

love.mousepressed = function(x, y)
    for i, point in ipairs(vertices) do
        if ts.distance(x, y, point[1], point[2]) < vertex_radius then
            active_vertex_i = i
            break
        end
    end
end

love.mousereleased = function()
    active_vertex_i = 0
end

love.mousemoved = function(x, y)
    if active_vertex_i > 0 then
        vertices[active_vertex_i][1] = x
        vertices[active_vertex_i][2] = y
    end
end

local vertex_color = {rt.color_unpack(rt.Palette.GREEN_4)}
local active_vertex_color = {rt.color_unpack(rt.Palette.GREEN_1)}

local black = {rt.color_unpack(rt.Palette.BLACK)}
local line_color = {rt.color_unpack(rt.Palette.RED_3)}
local vector_line_color = {rt.color_unpack(rt.Palette.BLUE_2)}
love.draw = function()
    if n_vertices == 0 then return end


    local a_x, a_y = table.unpack(vertices[1])
    local b_x, b_y = table.unpack(vertices[2])
    local c_x, c_y = table.unpack(vertices[3])
    local d_x, d_y = b_x + c_x - a_x, b_y + c_y - a_y

    love.graphics.setColor(table.unpack(line_color))
    love.graphics.line(a_x, a_y, b_x, b_y)
    love.graphics.line(a_x, a_y, c_x, c_y)

    love.graphics.setColor(table.unpack(vector_line_color))
    love.graphics.line(b_x, b_y, d_x, d_y)
    love.graphics.line(c_x, c_y, d_x, d_y)

    for i = 1, n_vertices do
        local x,y = table.unpack(vertices[i])
        love.graphics.setColor(table.unpack(black))
        love.graphics.circle("fill", x, y, vertex_radius + 2)

        if i == active_vertex_i then
            love.graphics.setColor(table.unpack(active_vertex_color))
        else
            love.graphics.setColor(table.unpack(vertex_color))
        end
        love.graphics.circle("fill", x, y, vertex_radius)
    end

    love.graphics.setColor(table.unpack(vector_line_color))
    love.graphics.circle("fill", d_x, d_y, vertex_radius)
end

--[[

local vertex_radius = 4

    for i = 1, i < 4 - 1 do
        love.graphics.setColor(table.unpack(line_color))
        local v1, v2 = corner_vertices[i], corner_vertices[i+1]
        love.graphics.line(
            v1[1], v1[2], v2[1], v2[2]
        )
    end

    for _, v in ipairs(corner_vertices) do
        love.graphics.setColor(table.unpack(black))
        love.graphcis.circle("fill", v[1], v[2], vertex_radius + 2)
        love.graphics.setColor(table.unpack(vertex_color))
        love.graphcis.circle("fill", v[1], v[2], vertex_radius)
    end
]]--