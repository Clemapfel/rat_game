--- @class rt.GradientDirection
rt.GradientDirection = meta.new_enum({
    LEFT_TO_RIGHT = 1,
    RIGHT_TO_LEFT = 2,
    TOP_TO_BOTTOM = 3,
    BOTTOM_TO_TOP = 4,
    TOP_LEFT_TO_BOTTOM_RIGHT = 5,
    TOP_RIGHT_TO_BOTTOM_LEFT = 6,
    BOTTOM_RIGHT_TO_TOP_LEFT = 7,
    BOTTOM_LEFT_TO_TOP_RIGHT = 8
})

--- @class rt.Gradient
--- @brief 2-tone gradient
rt.Gradient = meta.new_type("Gradient", function(x, y, width, height, color_from, color_to, type)
    if not meta.is_hsva(color_from) then meta.assert_rgba(color_from) end
    if not meta.is_hsva(color_to) then meta.assert_rgba(color_to) end

    if meta.is_hsva(color_from) then
        color_from = rt.hsva_to_rgba(color_from)
    end

    if meta.is_hsva(color_to) then
        color_to = rt.hsva_to_rgba(color_to)
    end

    if meta.is_nil(type) then
        type = rt.GradientDirection.LEFT_TO_RIGHT
    end
    meta.assert_enum(type, rt.GradientDirection)

    meta.assert_number(x, y, width, height)

    local out = meta.new(rt.Gradient, {
        _shape = rt.VertexRectangle(x, y, width, height),
        _color_from = color_from,
        _color_to = color_to,
        _type = type,
        _x = x,
        _y = y,
        _width = width,
        _height = height
    }, rt.Drawable)
    out:_update_color()
    return out
end)

--- @brief [internal]
function rt.Gradient:_update_color()
    meta.assert_isa(self, rt.Gradient)

    local set_color = function(i, color)
        self._shape:set_vertex_color(i, color)
    end

    local a = self._color_from
    local b = self._color_to
    local mix = rt.RGBA(
        mix(a.r, b.r, 0.5),
        mix(a.g, b.g, 0.5),
        mix(a.b, b.b, 0.5),
        mix(a.a, b.a, 0.5)
    )
    if self._type == rt.GradientDirection.LEFT_TO_RIGHT then
        set_color(1, a)
        set_color(4, a)
        set_color(2, b)
        set_color(3, b)
    elseif self._type == rt.GradientDirection.RIGHT_TO_LEFT then
        set_color(1, b)
        set_color(4, b)
        set_color(2, a)
        set_color(3, a)
    elseif self._type == rt.GradientDirection.TOP_TO_BOTTOM then
        set_color(1, a)
        set_color(2, a)
        set_color(3, b)
        set_color(4, b)
    elseif self._type == rt.GradientDirection.BOTTOM_TO_TOP then
        set_color(1, b)
        set_color(2, b)
        set_color(3, a)
        set_color(4, a)
    elseif self._type == rt.GradientDirection.TOP_LEFT_TO_BOTTOM_RIGHT then
        set_color(1, a)
        set_color(2, mix)
        set_color(3, b)
        set_color(4, mix)
    elseif self._type == rt.GradientDirection.BOTTOM_RIGHT_TO_TOP_LEFT then
        set_color(1, b)
        set_color(2, mix)
        set_color(3, a)
        set_color(4, mix)
    elseif self._type == rt.GradientDirection.TOP_RIGHT_TO_BOTTOM_LEFT then
        set_color(1, mix)
        set_color(2, a)
        set_color(3, mix)
        set_color(4, b)
    elseif self._type == rt.GradientDirection.BOTTOM_LEFT_TO_TOP_RIGHT then
        set_color(1, mix)
        set_color(2, b)
        set_color(3, mix)
        set_color(4, a)
    end
end

--- @overload rt.Drawable.draw
function rt.Gradient:draw()
    meta.assert_isa(self, rt.Gradient)
    if not self:get_is_visible() then return end

    self._shape:draw()
end

function rt.Gradient:_update_shape()
    meta.assert_isa(self, rt.Gradient)
    self._shape:resize(rt.AABB(self._x, self._y, self._width, self._height))
end

--- @brief
function rt.Gradient:set_position(x, y)
    meta.assert_isa(self, rt.Gradient)
    meta.assert_number(x, y)
    self._x = x
    self._y = y
    self:_update_shape()
end

--- @brief
function rt.Gradient:set_size(width, height)
    meta.assert_isa(self, rt.Gradient)
    meta.assert_number(width, height)
    self._width = width
    self._height = height
    self:_update_shape()
end

--- @bief
function rt.Gradient:resize(x, y, width, height)
    meta.assert_isa(self, rt.Gradient)
    self._x = x
    self._y = y
    self._width = width
    self._height = height
    self:_update_shape()
end

--- @brief
function rt.Gradient:set_color(color_from, color_to)
    meta.assert_isa(self, rt.Gradient)
    if not meta.is_hsva(color_from) then
        meta.assert_rgba(color_from)
    end

    if not meta.is_hsva(color_to) then
        meta.assert_rgba(color_to)
    end

    self._color_from = ternary(meta.is_hsva(color_from), rt.hsva_to_rgba(color_from), color_from)
    self._color_to = ternary(meta.is_hsva(color_to), rt.hsva_to_rgba(color_to), color_to)
    self:_update_color()
end

--- @brief
--- @return (rt.RGBA, rt.RGBA)
function rt.Gradient:get_color()
    meta.assert_isa(self, rt.Gradient)
    return self._color_from, self._color_to
end

--- @class rt.CircularGradient
rt.CircularGradient = meta.new_type("CircularGradient", function(center_x, center_y, radius, color_from, color_to, n_outer_vertices)

    meta.assert_number(center_x, center_y, radius)
    if not meta.is_hsva(color_from) then meta.assert_rgba(color_from) end
    if not meta.is_hsva(color_to) then meta.assert_rgba(color_to) end

    if meta.is_nil(n_outer_vertices) then
        n_outer_vertices = 64
    end
    meta.assert_number(n_outer_vertices)

    if meta.is_hsva(color_from) then
        color_from = rt.hsva_to_rgba(color_from)
    end

    if meta.is_hsva(color_to) then
        color_to = rt.hsva_to_rgba(color_to)
    end

    local out = meta.new(rt.CircularGradient, {
        _shape = {},
        _color_from = color_from,
        _color_to = color_to,
        _center_x = center_x,
        _center_y = center_y,
        _radius_x = radius,
        _radius_y = radius
    }, rt.Drawable)

    local step = 360 / n_outer_vertices
    local vertices = {}
    table.insert(vertices, rt.Vector2(center_x, center_y))

    local angle = 0
    while angle <= 360 + step do
        local as_radians = angle * math.pi / 180
        table.insert(vertices, rt.Vector2(
            center_x + math.cos(as_radians) * out._radius_x,
            center_y + math.sin(as_radians) * out._radius_y
        ))
        angle = angle + step
    end

    out._shape = rt.VertexShape(table.unpack(vertices))
    out:_update_color()
    return out
end)

--- @overload rt.Drawable.draw
function rt.CircularGradient:draw()
    meta.assert_isa(self, rt.CircularGradient)
    if self:get_is_visible() then
        self._shape:draw()
    end
end

--- @brief
function rt.CircularGradient:_update_shape()
    meta.assert_isa(self, rt.CircularGradient)

    local radius_x = self._radius_x
    local radius_y = self._radius_y

    local step = 360 / (self._shape:get_n_vertices() - 2)
    local vertices = {}
    self._shape:set_vertex_position(1, self._center_x, self._center_y)

    local angle = 0
    for i = 2, self._shape:get_n_vertices() do
        local as_radians = angle * math.pi / 180
        self._shape:set_vertex_position(i,
            self._center_x + math.cos(as_radians) * self._radius_x,
            self._center_y + math.sin(as_radians) * self._radius_y
        )
        angle = angle + step
    end
end

--- @brief
function rt.CircularGradient:_update_color()
    meta.assert_isa(self, rt.CircularGradient)
    self._shape:set_color(self._color_to)
    self._shape:set_vertex_color(1, self._color_from)
end

--- @brief
function rt.CircularGradient:set_position(center_x, center_y)
    meta.assert_isa(self, rt.CircularGradient)
    meta.assert_number(center_x, center_y)
    self._center_x = center_x
    self._center_y = center_y
    self:_update_shape()
end

--- @brief
function rt.CircularGradient:set_radius(radius_x, radius_y)
    meta.assert_isa(self, rt.CircularGradient)
    if meta.is_nil(radius_y) then radius_y = radius_y end
    meta.assert_number(radius_x, radius_y)

    self._radius_x = radius_x
    self._radius_y = radius_y
    self:_update_shape()
end

--- @brief [internal]
function rt.test.gradient()
    gradient = rt.CircularGradient(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5, 200, rt.RGBA(0, 0, 0, 1), rt.RGBA(0, 0, 0, 0))
    gradient = rt.Gradient(200, 200, 400, 500, rt.RGBA(0, 0, 0, 1), rt.RGBA(0, 0, 0, 0))
    gradient:set_position(200, 300)
    error("TODO")
end