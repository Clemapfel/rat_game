--- @class rt.Ellipse
rt.Ellipse = meta.class("Ellipse", rt.Shape)

--- @brief
function rt.Ellipse:instantiate(x, y, x_radius, y_radius, n_outer_vertices)
    meta.install(self, {
        _x = x,
        _y = y,
        _x_radius = x_radius,
        _y_radius = which(y_radius, x_radius),
        _n_outer_vertices = n_outer_vertices -- may be nil
    })
end
rt.Circle = rt.Ellipse

--- @overload
function rt.Ellipse:draw()
    love.graphics.setColor(self._color_r, self._color_g, self._color_b, self._color_a)

    if self._outline_mode == "line" then
        love.graphics.setLineWidth(self._line_width)
    end

    love.graphics.ellipse(
        self._outline_mode,
        self._x,
        self._y,
        self._x_radius,
        self._y_radius,
        self._n_outer_vertices
    )
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
    if x_radius == nil then x_radius = self._x_radius end
    if y_radius == nil then y_radius = x_radius end
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

--- @brief
function rt.Ellipse:set_n_outer_vertices(n)
    self._n_outer_vertices = n
end