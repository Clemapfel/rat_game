--- @class rt.Shape
rt.Shape = meta.new_type("Shape", function()
    error("In rt.Shape(): called abstract constructor")
end)

rt.Shape._color = rt.RGBA()
rt.Shape._is_outline = false

--- @brief [internal] bind all shape properties
function rt.Shape:_bind_for_rendering()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
end

--- @brief set color of all vertices
--- @param rgba rt.RGBA
function rt.Shape:set_color(rgba)
    meta.assert_isa(self, rt.Shape)
    if rt.is_rgba(rgba) then
        self._color = rgba
    elseif rt.is_hsva(rgba) then
        self._color = rt.hsva_to_rgba(rgba)
    else
        rt.assert_rgba(rgba)
    end
end

--- @brief get color of all vertices
function rt.Shape:get_color()
    meta.assert_isa(self, rt.Shape)
    return self._color
end

--- @brief set whether the shape should be rendered without a volume
--- @param b Boolean
function rt.Shape:set_is_outline(b)
    meta.assert_isa(self, rt.Shape)
    self._is_outline = b
end

--- @brief get whether the shape should be rendered without a volume
--- @return Boolean
function rt.Shape:get_is_outline()
    meta.assert_isa(self, rt.Shape)
    return self._is_outline
end

--- @brief [internal] convert to love.graphics.DrawMode
--- @return String
function rt.Shape:_get_draw_mode()
    meta.assert_isa(self, rt.Shape)
    if self._is_outline then return "line" else return "fill" end
end

--- @class rt.PointShape
rt.PointShape = meta.new_type("PointShape", function(x, y)
    meta.assert_number(x, y)
    return meta.new(rt.PointShape, {
        _vertices = {x, y}
    }, rt.Shape, rt.Drawable)
end)

function rt.PointShape:draw()
    self:_bind_for_rendering()
    love.graphics.point(self._vertices[1], self._vertcies[2])
end

--- @class rt.PointsShape
rt.PointsShape = meta.new_type("PointsShape", function(x, y, ...)
    meta.assert_number(x, y, ...)
    assert(sizeof({...}) % 2 == 0)
    return meta.new(rt.PointsShape, {
        _vertices = {...}
    }, rt.Shape, rt.Drawable)
end)

function rt.PointsShape:draw()
    self:_bind_for_rendering()
    love.graphics.points(table.unpack(self._vertices))
end

--- @class rt.LineStripShape
rt.LineStripShape = meta.new_type("LineStripShape", function(a_x, a_y, b_x, b_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, ...)
    assert(sizeof({...}) % 2 == 0)
    return meta.new(rt.LineStripShape, {
        _vertices = {a_x, a_y, b_x, b_y, ...},
        _is_loop = false
    }, rt.Shape, rt.Drawable)
end)

--- @class rt.LineShape
function rt.LineShape(a_x, a_y, b_x, b_y)
    return rt.LineStripShape(a_x, a_y, b_x, b_y)
end

--- @class rt.LineLoopShape
function rt.LineLoopShape(a_x, a_y, b_x, b_y, ...)
    local out = rt.LineStripShape(a_x, a_y, b_x, b_y, ...)
    out._is_loop = true
    return out
end

--- @class rt.LineStripShape
function rt.LineStripShape:draw()
    self:_bind_for_rendering()
    if self._is_loop then
        local vertices = {}
        for _, v in ipairs(self._vertices) do
            table.insert(vertices, v)
        end
        table.insert(vertices, self._vertices[1])
        table.insert(vertices, self._vertices[2])
        love.graphics.line(table.unpack(vertices))
    else
        love.graphics.line(table.unpack(self._vertices))
    end
end

--- @class rt.RectangleShape
rt.RectangleShape = meta.new_type("RectangleShape", function(top_left_x, top_left_y, width, height, border_radius)
    if meta.is_nil(border_radius) then border_radius = 0 end
    meta.assert_number(top_left_x, top_left_y, width, height)

    return meta.new(rt.RectangleShape, {
        _x = top_left_x,
        _y = top_left_y,
        _w = width,
        _h = height,
        _border_radius = border_radius
    }, rt.Shape, rt.Drawable)
end)

--- @class rt.SquareShape
function rt.SquareShape(top_left_x, top_left_y, size)
    return rt.RectangleShape(top_left_x, top_left_y, size, size)
end

function rt.RectangleShape:draw()
    self:_bind_for_rendering()
    love.graphics.rectangle(self:_get_draw_mode(), self._x, self._y, self._w, self._h, self._border_radius, self._border_radius, self._border_radius * 2)
end

--- @class rt.TriangleShape
rt.TriangleShape = meta.new_type("TriangleShape", function(a_x, a_y, b_x, b_y, c_x, c_y)
    meta.assert_number(a_x, a_y, b_x, b_y, c_x, c_y)
    return meta.new(rt.TriangleShape, {
        _vertices = {a_x, a_y, b_x, b_y, c_x, c_y}
    }, rt.Shape, rt.Drawable)
end)

function rt.TriangleShape:draw()
    self:_bind_for_rendering()
    local vs = self._vertices
    love.graphics.triangle(self:_get_draw_mode(), vs[1], vs[2], vs[3], vs[4], vs[5], vs[6])
end

--- @class rt.EllipseShape
rt.EllipseShape = meta.new_type("EllipseShape", function(center_x, center_y, x_radius, y_radius, n_outer_vertices)
    meta.assert_number(center_x, center_y, x_radius, y_radius)
    if meta.is_nil(n_outer_vertices) then
        n_outer_vertices = 0
    end
    meta.assert_number(n_outer_vertices)

    return meta.new(rt.EllipseShape, {
        _center_x = center_x,
        _center_y = center_y,
        _x_radius = x_radius,
        _y_radius = y_radius,
        _n_outer_vertices = n_outer_vertices
    }, rt.Shape, rt.Drawable)
end)

function rt.CircleShape(center_x, center_y, radius, n_outer_vertices)
    return rt.EllipseShape(center_x, center_y, radius, radius, n_outer_vertices)
end

function rt.EllipseShape:draw()
    self:_bind_for_rendering()
    if self._n_outer_vertices > 0 then
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._x_radius, self._y_radius, self._n_outer_vertices)
    else
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._x_radius, self._y_radius)
    end
end

--- @class rt.PolygonShape
rt.PolygonShape = meta.new_type("PolygonShape", function(a_x, a_y, b_x, b_y, c_x, c_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, c_x, c_y)

    local decomposition = love.math.triangulate({a_x, a_y, b_x, b_y, c_x, c_y, ...})

    local vertices = {}
    for _, triangle in ipairs(decomposition) do
        for _, vertex in ipairs(triangle) do
            table.insert(vertices, vertex)
        end
    end

    return meta.new(rt.PolygonShape, {
        _vertices = vertices
    }, rt.Shape, rt.Drawable)
end)

function rt.PolygonShape:draw()
    self:_bind_for_rendering()
    love.graphics.polygon(self:_get_draw_mode(), table.unpack(self._vertices))
end
