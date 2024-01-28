--- @class
rt.Rectangle = meta.new_type("Rectangle", function(top_left_x, top_left_y, width, height)
    return meta.new(rt.Rectangle, {
        _x = top_left_x,
        _y = top_left_y,
        _width = width,
        _height = height,
        _corner_radius = 0
    }, rt.Shape, rt.Drawable)
end)

--- @overload
function rt.Rectangle:draw()
    self:_bind_properties()
    love.graphics.rectangle(
        ternary(self:get_is_outline(), "line", "fill"),
        self._x, self._y,
        self._width, self._height,
        self._corner_radius, self._corner_radius, self._corner_radius * 2
    )
    self:_unbind_properties()
end

--- @brief
function rt.Rectangle:set_corner_radius(x)
    self._corner_radius = x
end

--- @brief
function rt.Rectangle:get_corner_radius()
    return self._corner_radius
end

--- @brief
function rt.Rectangle:get_bounds()
    return rt.AABB(self._x, self._y, self._width, self._height)
end

--- @brief
function rt.Rectangle:resize(x, y, width, height)
    self._x = x
    self._y = y
    self._width = width
    self._height = height
end

--- @brief
function rt.Rectangle:get_size()
    return self._width, self._height
end

--- @brief
function rt.Rectangle:get_width()
    return self._width
end

--- @brief
function rt.Rectangle:get_height()
    return self._height
end

--- @brief
function rt.Rectangle:set_top_left(x, y)
    self._x = x
    self._y = y
end

--- @brief
function rt.Rectangle:get_top_left()
    return self._x, self._y
end

--- @brief
function rt.Rectangle:set_centroid(x, y)
    self:set_top_left(x - 0.5 * self._width, y - 0.5 * self._height)
end

--- @brief
function rt.Rectangle:get_centroid()
    return self._x + 0.5 * self._width, self._y + 0.5 * self._height
end

