--- @class rt.LineJoin
rt.LineJoin = meta.new_enum({
    MITER = "miter",
    NONE = "none",
    BEVEL = "bevel"
})

--- @class rt.Shape
rt.Shape = meta.new_type("Shape", function()
    error("In rt.Shape(): called abstract constructor")
end)

rt.Shape._color = rt.RGBA()
rt.Shape._is_outline = false
rt.Shape._anti_aliasing = true
rt.Shape._line_join = rt.LineJoin.MITER
rt.Shape._line_width = 1

--- @brief set how line vertices connect
--- @param style rt.LineJoin
function rt.Shape:set_line_join_style(style)
    self._line_join = style
end

--- @brief get how line vertices connect
--- @return rt.LineJoin
function rt.Shape:get_line_join_style()
    return self._line_join
end

--- @brief set whether smoothing should be applied
--- @param b Boolean
function rt.Shape:set_use_anti_aliasing(b)
    meta.assert_isa(self, rt.Shape)
    self._anti_aliasing = b
end

--- @brief get whether smoothing should be applied
--- @return Boolean
function rt.Shape:get_use_anti_aliasing()
    meta.assert_isa(self, rt.Shape)
    return self._anti_aliasing
end

--- @brief set line width
--- @param px Number
function rt.Shape:set_line_width(px)
    meta.assert_isa(self, rt.Shape)
    self._line_width = px
end

--- @brief get line width
--- @return Number
function rt.Shape:get_line_width()
    meta.assert_isa(self, rt.Shape)
    return self._line_width
end

--- @brief [internal] bind all shape properties
function rt.Shape:_bind_for_rendering()
    meta.assert_isa(self, rt.Shape)

    if self:get_use_anti_aliasing() then
        love.graphics.setLineStyle("smooth")
    else
        love.graphics.setLineStyle("rough")
    end

    love.graphics.setLineWidth(self._line_width)
    love.graphics.setPointSize(self._line_width)

    love.graphics.setLineJoin(self._line_join)
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

--- @class rt.Point
rt.Point = meta.new_type("Point", function(x, y)
    meta.assert_number(x, y)
    return meta.new(rt.Point, {
        _vertices = {x, y}
    }, rt.Shape, rt.Drawable)
end)

function rt.Point:draw()
    self:_bind_for_rendering()
    love.graphics.point(self._vertices[1], self._vertcies[2])
end

--- @class rt.Points
rt.Points = meta.new_type("Points", function(x, y, ...)
    meta.assert_number(x, y, ...)
    assert(sizeof({...}) % 2 == 0)
    return meta.new(rt.Points, {
        _vertices = {...}
    }, rt.Shape, rt.Drawable)
end)

function rt.Points:draw()
    self:_bind_for_rendering()
    love.graphics.points(table.unpack(self._vertices))
end

--- @class rt.LineStrip
rt.LineStrip = meta.new_type("LineStrip", function(a_x, a_y, b_x, b_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, ...)
    assert(sizeof({...}) % 2 == 0)
    return meta.new(rt.LineStrip, {
        _vertices = {a_x, a_y, b_x, b_y, ...},
        _is_loop = false
    }, rt.Shape, rt.Drawable)
end)

--- @class rt.Line
function rt.Line(a_x, a_y, b_x, b_y)
    return rt.LineStrip(a_x, a_y, b_x, b_y)
end

--- @class rt.LineLoop
function rt.LineLoop(a_x, a_y, b_x, b_y, ...)
    local out = rt.LineStrip(a_x, a_y, b_x, b_y, ...)
    out._is_loop = true
    return out
end

function rt.LineStrip:draw()
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

--- @class rt.Rectangle
rt.Rectangle = meta.new_type("Rectangle", function(top_left_x, top_left_y, width, height, border_radius)
    if meta.is_nil(border_radius) then border_radius = 0 end
    meta.assert_number(top_left_x, top_left_y, width, height)

    return meta.new(rt.Rectangle, {
        _x = top_left_x,
        _y = top_left_y,
        _w = width,
        _h = height,
        _border_radius = border_radius
    }, rt.Shape, rt.Drawable)
end)

--- @class rt.Square
function rt.Square(top_left_x, top_left_y, size)
    return rt.Rectangle(top_left_x, top_left_y, size, size)
end

function rt.Rectangle:draw()
    self:_bind_for_rendering()
    love.graphics.rectangle(self:_get_draw_mode(), self._x, self._y, self._w, self._h, self._border_radius, self._border_radius, self._border_radius * 2)
end

--- @class rt.Ellipse
rt.Ellipse = meta.new_type("Ellipse", function(center_x, center_y, x_radius, y_radius, n_outer_vertices)
    meta.assert_number(center_x, center_y, x_radius, y_radius)
    if meta.is_nil(n_outer_vertices) then
        n_outer_vertices = 0
    end
    meta.assert_number(n_outer_vertices)

    return meta.new(rt.Ellipse, {
        _center_x = center_x,
        _center_y = center_y,
        _x_radius = x_radius,
        _y_radius = y_radius,
        _n_outer_vertices = n_outer_vertices
    }, rt.Shape, rt.Drawable)
end)

function rt.Circle(center_x, center_y, radius, n_outer_vertices)
    return rt.Ellipse(center_x, center_y, radius, radius, n_outer_vertices)
end

function rt.Ellipse:draw()
    self:_bind_for_rendering()
    if self._n_outer_vertices > 0 then
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._x_radius, self._y_radius, self._n_outer_vertices)
    else
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._x_radius, self._y_radius)
    end
end

--- @class rt.Polygon
rt.Polygon = meta.new_type("Polygon", function(a_x, a_y, b_x, b_y, c_x, c_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, c_x, c_y)

    local vertices =  {a_x, a_y, b_x, b_y, c_x, c_y, ...}
    local outer_hull = vertices

    -- TODO: compute outer hull

    for _, triangle in ipairs(outer_hull) do
        for _, vertex in ipairs(triangle) do
            table.insert(vertices, vertex)
        end
    end

    return meta.new(rt.Polygon, {
        _vertices = vertices
    }, rt.Shape, rt.Drawable)
end)

--- @class rt.Triangle
function rt.Triangle(a_x, a_y, b_x, b_y, c_x, c_y)
   return rt.Polygon(a_x, a_y, b_x, b_y, c_x, c_y)
end

function rt.Polygon:draw()
    self:_bind_for_rendering()
    love.graphics.polygon(self:_get_draw_mode(), table.unpack(self._vertices))
end
