--- @class rt.Ellipse
rt.Ellipse = meta.new_type("Ellipse", rt.Shape, function(x, y, x_radius, y_radius)
    return meta.new(rt.Ellipse, {
        _x = x,
        _y = y,
        _x_radius = x_radius,
        _y_radius = which(y_radius, x_radius)
    })
end)
rt.Circle = rt.Ellipse

--- @overload
function rt.Ellipse:draw()
    self:_bind_properties()
    love.graphics.ellipse(
            ternary(self:get_is_outline(), "line", "fill"),
            self._x,
            self._y,
            self._x_radius,
            self._y_radius
    )
    self:_unbind_properties()
end

--- @overload
function rt.Ellipse:get_bounds()
    return rt.AABB(
            self._x - self._x_radius,
            self._y - self._y_radius,
            self._x_radius * 2,
            self._y_radius * 2
    )
end

--- @overload
function rt.Ellipse:resize(x, y, x_radius, y_radius)
    self._x = x
    self._y = y
    self._x_radius = x_radius
    self._y_radius = y_radius
end

--- @brief
function rt.Ellipse:set_center(x, y)
    self._x = x
    self._y = y
end

--- @overload
rt.Ellipse.set_centroid = rt.Ellipse.set_center

--- @brief
function rt.Ellipse:get_center()
    return self._x, self._y
end

--- @overload
rt.Ellipse.get_centroid = rt.Ellipse.get_center

--- @brief
function rt.Ellipse:set_radius(x_radius, y_radius)
    self._x_radius = x_radius
    self._y_radius = which(y_radius, x_radius)
end

--- @brief
function rt.Ellipse:get_radius()
    return self._x_radius, self._y_radius
end