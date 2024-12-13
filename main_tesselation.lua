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

n_horizontal_vertices = 0
n_vertical_vertices = 0

a_x, a_y = 0, 0
b_x, b_y = 0, 0
c_x, c_y = 0, 0
d_x, d_y = 0, 0

active_vertex = 0 -- 0 none, 1 top left, 2 top right, 3 bottom right, 4 bottom left
vertex_radius = 15

love.load = function(delta)
    local center_x, center_y = 0.5 * love.graphics.getWidth(), 0.5 * love.graphics.getHeight()
    local x_radius, y_radius = 200, 100
    
    a_x, a_y = center_x, center_y
    b_x, b_y = center_x + x_radius, center_y
    c_x, c_y = center_x + x_radius, center_y + y_radius
    d_x, d_y = center_x, center_y + y_radius
end

love.mousepressed = function(x, y)
    if ts.distance(x, y, a_x, a_y) < vertex_radius then
        active_vertex = 1
    elseif ts.distance(x, y, b_x, b_y) < vertex_radius then
        active_vertex = 2
    elseif ts.distance(x, y, c_x, c_y) < vertex_radius then
        active_vertex = 3
    elseif ts.distance(x, y, d_x, d_y) < vertex_radius then
        active_vertex = 4
    end
end

love.mousereleased = function()
    active_vertex = 0
end

love.mousemoved = function(x, y)
    if active_vertex > 0 then
        if active_vertex == 1 then
            a_x, a_y = x, y
        elseif active_vertex == 2 then
            b_x, b_y = x, y
        elseif active_vertex == 3 then
            c_x, c_y = x, y
        elseif active_vertex == 4 then
            d_x, d_y = x, y
        end
    end
end

local vertex_color = {rt.color_unpack(rt.Palette.GREEN_4)}
local active_vertex_color = {rt.color_unpack(rt.Palette.GREEN_1)}

local black = {rt.color_unpack(rt.Palette.BLACK)}
local line_color = {rt.color_unpack(rt.Palette.RED_3)}

do
    local _draw_vertex = function(i, x, y)
        love.graphics.setColor(table.unpack(black))
        love.graphics.circle("fill", x, y, vertex_radius + 2)

        if active_vertex == i then
            love.graphics.setColor(table.unpack(active_vertex_color))
        else
            love.graphics.setColor(table.unpack(vertex_color))
        end
        love.graphics.circle("fill", x, y, vertex_radius)
    end

    love.draw = function()
        love.graphics.setLineWidth(3)
        love.graphics.setColor(table.unpack(line_color))
        love.graphics.line(
            a_x, a_y,
            b_x, b_y,
            c_x, c_y,
            d_x, d_y,
            a_x, a_y
        )

        _draw_vertex(1, a_x, a_y)
        _draw_vertex(2, b_x, b_y)
        _draw_vertex(3, c_x, c_y)
        _draw_vertex(4, d_x, d_y)
    end
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