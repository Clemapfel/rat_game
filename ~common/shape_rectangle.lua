--- @class
rt.Rectangle = meta.class("Rectangle", rt.Shape)

function rt.Rectangle:instantiate(top_left_x, top_left_y, width, height)
    meta.install(self, {
        _x = top_left_x,
        _y = top_left_y,
        _width = width,
        _height = height,
        _corner_radius = 0
    })
end

--- @overload
function rt.Rectangle:draw()
    love.graphics.setColor(self._color_r, self._color_g, self._color_b, self._color_a)
    if self._outline_mode == "line" then
        love.graphics.setLineWidth(self._line_width)
        if self._line_join ~= nil then
            love.graphics.setLineJoin(self._line_join)
        end
    end

    love.graphics.rectangle(
        self._outline_mode,
        self._x, self._y,
        self._width, self._height,
        self._corner_radius
    )
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
function rt.Rectangle:resize(x, y, width, height)
    if meta.is_aabb(x) then
        local aabb = x
        self._x = aabb.x
        self._y = aabb.y
        self._width = aabb.width
        self._height = aabb.height
    else
        meta.assert_number(x, y, width, height)
        self._x = x
        self._y = y
        self._width = width
        self._height = height
    end
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

