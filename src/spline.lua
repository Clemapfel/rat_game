--- @class rt.Spline
rt.Spline = meta.new_type("Spline", function(points)
    local out = meta.new(rt.Spline, {
        _points = rt.Spline._catmull_rom(points, true)
    }, rt.Drawable)
    return out
end)

function rt.Spline._catmull_rom(points, closed, steps, steprate)

    -- source: https://gist.github.com/HoraceBury/4afb0e68cd807d8ead220a709219db2e

    function _range(tbl, index, count)
        count = count or #tbl-index+1
        local output = {}
        for i=index, index+count-1 do
            output[#output+1] = tbl[i]
        end
        return output
    end

    function _length_of(ax, ay, bx, by)
        local width, height = bx - ax, by - ay
        return math.sqrt(width*width + height*height)
    end

    steprate = which(steprate, 15)
    steps = which(steps, 5)

    if (#points < 6) then
        return points
    end

    local firstX, firstY, secondX, secondY = splat(_range(points, 1, 4))
    local penultX, penultY, lastX, lastY = splat(_range(points, #points-3, 4))

    --if (closed) then
    --    points = table.copy({ penultX, penultY, lastX, lastY } , points, { firstX, firstY, secondX, secondY })
    --end

    local spline = {}
    local start, count = 1, #points-2
    local p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y
    local x, y

    if (closed) then
        start = 3
        count = #points-5
    end

    for i=start, count, 2 do
        if (not closed and i==1) then
            p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = points[i], points[i+1], points[i], points[i+1], points[i+2], points[i+3], points[i+4], points[i+5]
            steps = _length_of(p1x,p1y , p3x,p3y)
        elseif (not closed and i==count-1) then
            p0x, p0y, p1x, p1y, p2x, p2y = splat(_range(points, #points-5, 6))
            p3x, p3y = points[#points-1], points[#points]
            steps = _length_of(p1x,p1y , p3x,p3y)
        else
            p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = splat(_range(points, i-2, 8))
            steps = _length_of(p0x,p0y , p1x,p1y)
        end

        for t=0, 1, 1 / (steps/steprate) do
            x = 0.5 * ((2 * p1x) + (p2x - p0x) * t + (2 * p0x - 5 * p1x + 4 * p2x - p3x) * t * t + (3 * p1x - p0x - 3 * p2x + p3x) * t * t * t)
            y = 0.5 * ((2 * p1y) + (p2y - p0y) * t + (2 * p0y - 5 * p1y + 4 * p2y - p3y) * t * t + (3 * p1y - p0y - 3 * p2y + p3y) * t * t * t)

            -- prevent duplicate entries
            if (not(#spline > 0 and spline[#spline-1] == x and spline[#spline] == y)) then
                spline[#spline+1] = x
                spline[#spline+1] = y
            end
        end
    end

    if (closed) then
        table.remove(points,1)
        table.remove(points,1)
        table.remove(points,#points)
        table.remove(points,#points)
    end

    return spline
end

--- @overload
function rt.Spline:draw()
    love.graphics.line(splat(self._points))
end
