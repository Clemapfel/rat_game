--- @class rt.LineJoin
rt.LineJoin = meta.new_enum({
    MITER = "miter",
    NONE = "none",
    BEVEL = "bevel"
})

--- @class rt.Shape
rt.Shape = meta.new_abstract_type("Shape")

rt.Shape._color = rt.RGBA()
rt.Shape._is_outline = false
rt.Shape._anti_aliasing = true
rt.Shape._line_join = rt.LineJoin.MITER
rt.Shape._line_width = 1
rt.Shape._rotation = 0 -- radians
rt.Shape._origin_x = 0
rt.Shape._origin_y = 0
rt.Shape._use_origin = false

--- @brief get centroid
function rt.Shape:get_centroid()
    error("In " .. meta.typeof(self) .. "get_centroid: abstract method called")
end

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

--- @brief set rotation
function rt.Shape:set_rotation(angle, origin_x, origin_y)
    meta.assert_isa(self, rt.Shape)
    meta.assert_isa(angle, rt.Angle)
    self._rotation = angle:as_radians()
    self._use_origin = false

    if not meta.is_nil(origin_x) then
        meta.assert_number(origin_x, origin_y)
        self._use_origin = true
    end
end

--- @brief get_rotation
function rt.Shape:get_rotation()
    meta.assert_isa(self, rt.Shape)
    return self._rotation
end

--- @brief [internal] bind all shape properties
function rt.Shape:_bind()
    meta.assert_isa(self, rt.Shape)
    
    love.graphics.push()

    if self:get_use_anti_aliasing() then
        love.graphics.setLineStyle("smooth")
    else
        love.graphics.setLineStyle("rough")
    end

    love.graphics.setLineWidth(self._line_width)
    love.graphics.setPointSize(self._line_width)

    love.graphics.setLineJoin(self._line_join)
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)

    if self._rotation ~= 0 then
        local center_x, center_y = self._origin_x, self._origin_y
        if not self._use_origin then
            center_x, center_y = self:get_centroid()
        end
        love.graphics.translate(center_x, center_y)
        love.graphics.rotate(self._rotation)
        love.graphics.translate(-1 * center_x, -1 * center_y)
    end
end

--- @brief unbind properties
function rt.Shape:_unbind()
    love.graphics.pop()
end

--- @brief set color of all vertices
--- @param rgba rt.RGBA
function rt.Shape:set_color(rgba)
    meta.assert_isa(self, rt.Shape)
    if meta.is_rgba(rgba) then
        self._color = rgba
    elseif meta.is_hsva(rgba) then
        self._color = rt.hsva_to_rgba(rgba)
    else
        meta.assert_rgba(rgba)
    end
end

--- @brief get color of all vertices
function rt.Shape:get_color()
    meta.assert_isa(self, rt.Shape)
    return self._color
end

--- @brief
function rt.Shape:set_rotation(angle)
    meta.assert_isa(self, rt.Shape)
    meta.assert_isa(angle, rt.Angle)
    self._rotation = angle:as_radians()
end

--- @brief
--- @return rt.Angle
function rt.Shape:get_rotation()
    meta.assert_isa(self, rt.Shape)
    return rt.radians(self._rotation)
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

--- @overload rt.Shape.get_centroid
function rt.Point:get_centroid()
    return self._vertices.x, self._vertices.y
end

function rt.Point:draw()
    if not self:get_is_visible() then return end
    self:_bind()
    love.graphics.point(self._vertices[1], self._vertcies[2])
    self:_unbind()
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
    if not self:get_is_visible() then return end
    self:_bind()
    love.graphics.points(table.unpack(self._vertices))
    self:_unbind()
end

--- @brief
function rt.Shape:_compute_centroid()
    local x_sum = 0
    local y_sum = 0
    local n = sizeof(self._vertices)

    for i = 1, n, 2 do
        x_sum = x_sum + self._vertices[i]
        y_sum = y_sum + self._vertices[i+1]
    end
    self._centroid_x = 2 * x_sum / n
    self._centroid_y = 2 * y_sum / n
end

--- @class rt.LineStrip
rt.LineStrip = meta.new_type("LineStrip", function(a_x, a_y, b_x, b_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, ...)
    assert(sizeof({...}) % 2 == 0)
    local out = meta.new(rt.LineStrip, {
        _vertices = {a_x, a_y, b_x, b_y, ...},
        _is_loop = false,
        _centroid_x = 0,
        _centroid_y = 0
    }, rt.Shape, rt.Drawable)
    out:_compute_centroid()
    return out
end)

--- @overload rt.Shape:get_centroid
function rt.LineStrip:get_centroid()
    meta.assert_isa(self, rt.LineStrip)
    return self._centroid_x, self._centroid_y
end

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

--- @brief
function rt.LineStrip:resize(a_x, a_y, b_x, b_y, ...)
    meta.assert_isa(self, rt.LineStrip)
    self._vertices = {a_x, a_y, b_x, b_y, ...}
    self:_compute_centroid()
end

--- @brief
function rt.LineStrip:draw()
    if not self:get_is_visible() then return end
    self:_bind()
    if self._is_loop then
        local vertices = {}
        for _, v in pairs(self._vertices) do
            table.insert(vertices, v)
        end
        table.insert(vertices, self._vertices[1])
        table.insert(vertices, self._vertices[2])
        love.graphics.line(table.unpack(vertices))
    else
        love.graphics.line(table.unpack(self._vertices))
    end
    self._unbind()
end

--- @class rt.Rectangle
rt.Rectangle = meta.new_type("Rectangle", function(top_left_x, top_left_y, width, height, corner_radius)
    if meta.is_nil(corner_radius) then corner_radius = 0 end
    meta.assert_number(top_left_x, top_left_y, width, height)

    return meta.new(rt.Rectangle, {
        _x = top_left_x,
        _y = top_left_y,
        _w = width,
        _h = height,
        _corner_radius = corner_radius
    }, rt.Shape, rt.Drawable)
end)

--- @overload rt.Shape.get_centroid()
function rt.Rectangle:get_centroid()
    return self._x + 0.5 * self._width, self._y + 0.5 * self._height
end

--- @class rt.Square
function rt.Square(top_left_x, top_left_y, size)
    return rt.Rectangle(top_left_x, top_left_y, size, size)
end

function rt.Rectangle:draw()
    if not self:get_is_visible() then return end
    self:_bind()
    love.graphics.rectangle(self:_get_draw_mode(), self._x, self._y, self._w, self._h, self._corner_radius, self._corner_radius, self._corner_radius * 2)
    self._unbind()
end

--- @brief TODO
function rt.Rectangle:set_position(x, y)
    meta.assert_isa(self, rt.Rectangle)
    meta.assert_number(x, y)
    self._x = x
    self._y = y
end

--- @brief TODO
function rt.Rectangle:set_size(width, height)
    meta.assert_isa(self, rt.Rectangle)
    meta.assert_number(width, height)
    self._w = width
    self._h = height
end

--- @brief TODO
function rt.Rectangle:get_size()
    meta.assert_isa(self, rt.Rectangle)
    return self._w, self._h
end

--- @brief TODO
function rt.Rectangle:set_corner_radius(px)
    meta.assert_isa(self, rt.Rectangle)
    self._corner_radius = px
end

--- @brief TODO
function rt.Rectangle:resize(aabb)
    meta.assert_aabb(aabb)
    self._x = aabb.x
    self._y = aabb.y
    self._w = aabb.width
    self._h = aabb.height
end

--- @brief TODO
function rt.Rectangle:get_bounds()
    return rt.AABB(self._x, self._y, self._w, self._h)
end

--- @brief TODO
function rt.Rectangle:get_position()
    local bounds = self:get_bounds()
    return bounds.x, bounds.y
end

--- @brief TODO
function rt.Rectangle:get_size()
    local bounds = self:get_bounds()
    return bounds.width, bounds.height
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
        _radius_x = x_radius,
        _radius_y = y_radius,
        _n_outer_vertices = n_outer_vertices
    }, rt.Shape, rt.Drawable)
end)

--- @overload rt.Shape:get_centroid
function rt.Ellipse:get_centroid()
    meta.assert_isa(self, rt.Ellipse)
    return self._center_x, self._center_y
end

--- @brief
function rt.Circle(center_x, center_y, radius, n_outer_vertices)
    return rt.Ellipse(center_x, center_y, radius, radius, n_outer_vertices)
end

--- @brief
function rt.Ellipse:set_radius(radius_x, radius_y)
    meta.assert_isa(self, rt.Ellipse)
    if not meta.is_nil(radius_y) then
        radius_y = radius_x
    end
    meta.assert_number(radius_x, radius_y)
    self._radius_x = radius_x
    self._radius_y = radius_y
end

--- @brief
function rt.Ellipse:resize(center_x, center_y, radius_x, radius_y)
    meta.assert_isa(self, rt.Ellipse)
    meta.assert_number(center_x, center_y, radius_x, radius_y)
    if not meta.is_nil(radius_y) then
        meta.assert_number(radius_y)
    end

    self._center_x = center_x
    self._center_y = center_y
    self._radius_x = radius_x
    self._radius_y = ternary(meta.is_nil(radius_y), radius_x, radius_y)
end

--- @brief
function rt.Ellipse:get_center()
    meta.assert_isa(self, rt.Ellipse)
    return self._center_x, self._center_y
end

--- @brief
function rt.Ellipse:set_center(x, y)
    meta.assert_isa(self, rt.Ellipse)
    meta.assert_number(x, y)
    self._center_x = x
    self._center_y = y
end

--- @brief
function rt.Ellipse:get_radius()
    meta.assert_isa(self, rt.Ellipse)
    return self._radius_x, self._radius_y
end

--- @brief
function rt.Ellipse:set_radius(radius_x, radius_y)
    meta.assert_isa(self, rt.Ellipse)
    meta.assert_number(radius_x)
    if not meta.is_nil(radius_y) then meta.assert_number(radius_y) end

    self._radius_x = radius_x
    self._radius_y = ternary(meta.is_nil(radius_y), radius_x, radius_y)
end

--- @brief
function rt.Ellipse:draw()
    meta.assert_isa(self, rt.Ellipse)
    if not self:get_is_visible() then return end
    self:_bind()

    if self._n_outer_vertices > 0 then
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._radius_x, self._radius_y, clamp(self._n_outer_vertices, 3))
    else
        love.graphics.ellipse(self:_get_draw_mode(), self._center_x, self._center_y, self._radius_x, self._radius_y)
    end

    self._unbind()
end

--- @class rt.Polygon
rt.Polygon = meta.new_type("Polygon", function(a_x, a_y, b_x, b_y, c_x, c_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, c_x, c_y)

    local vertices =  {a_x, a_y, b_x, b_y, c_x, c_y, ...}
    local outer_hull = love.math.triangulate(vertices)
    for _, triangle in pairs(outer_hull) do
        for _, vertex in pairs(triangle) do
            table.insert(vertices, vertex)
        end
    end

    local out = meta.new(rt.Polygon, {
        _vertices = vertices,
        _centroid_x = 0,
        _centroid_y = 0
    }, rt.Shape, rt.Drawable)
    out:_compute_centroid()
    return out
end)

function rt.Polygon:resize(a_x, a_y, b_x, b_y, c_x, c_y, ...)
    meta.assert_number(a_x, a_y, b_x, b_y, c_x, c_y)
    local vertices =  {a_x, a_y, b_x, b_y, c_x, c_y, ...}
    local outer_hull = love.math.triangulate(vertices)
    for _, triangle in pairs(outer_hull) do
        for _, vertex in pairs(triangle) do
            table.insert(vertices, vertex)
        end
    end
    self._vertices = vertices
    self:_compute_centroid()
end

--- @overload rt.Shape.get_centroid
function rt.Polygon:get_centroid()
    meta.assert_isa(self, rt.Polygon)
    local x_sum = 0
    local y_sum = 0
    local n = sizeof(self._vertices)
    for i = 1, n, 2 do
        x_sum = x_sum + self._vertices[i]
        y_sum = y_sum + self._vertices[i+1]
    end
    return x_sum / n, y_sum / n
end


--- @class rt.Triangle
function rt.Triangle(a_x, a_y, b_x, b_y, c_x, c_y)
   return rt.Polygon(a_x, a_y, b_x, b_y, c_x, c_y)
end

function rt.Polygon:draw()
    if not self:get_is_visible() then return end
    self:_bind()
    love.graphics.polygon(self:_get_draw_mode(), table.unpack(self._vertices))
    self._unbind()
end

--- @brief test shapes
function rt.test.shapes()
    error("TODO")
end

