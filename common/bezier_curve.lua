--- @class BezierCurve
rt.BezierCurve = meta.new_type("BezierCurve", rt.Drawable, function(points)
    return meta.new(rt.BezierCurve, {
        _native = love.math.newBezierCurve(points),
        _points = points,
        _length = {},
    })
end)

--- @brief
function rt.BezierCurve:at(x)
    return self._native:evaluate(clamp(x, 0, 1))
end

--- @brief
function rt.BezierCurve:draw()
    love.graphics.line(self._native:render())
end

--- @brief
function rt.BezierCurve:get_length()
    if not meta.is_number(self._length) then
        self._length = self:_calculate_length()
    end
    return self._length
end

--- @brief
function rt.BezierCurve:_calculate_length()

    if #self._points <= 2 then
        return 0
    end

    local vertices = self._native:render()
    local sum = 0
    for i = 1, #vertices - 2, 2 do
        local from_x, from_y = vertices[i], vertices[i+1]
        local to_x, to_y = vertices[i+2], vertices[i+3]
        sum = sum + rt.magnitude(from_x - to_x, from_y - to_y)
    end
    return sum
end