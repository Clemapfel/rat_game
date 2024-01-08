--- @class rt.Spline
--- @brief catmull-rom spline, c1 continuous and goes through every control point
rt.Spline = meta.new_type("Spline", function(points, loop)
    local vertices, distances, total_length = rt.Spline._catmull_rom(points, 20, loop)
    local out = meta.new(rt.Spline, {
        _vertices = vertices,
        _distances = distances,
        _length = total_length
    }, rt.Drawable)

    return out
end)

--- @brief
function rt.Spline:get_length()
    return self._length
end

--- @brief
--- @param
--- @return Number, Number
function rt.Spline:at(t)
    t = clamp(t, 0, 1)
    local i = 1

    local max_length = self._length
    local length = t * max_length

    while length > 0 and i <= #self._distances do
        local distance = self._distances[i]
        if length - distance <= 0 then
            break
        end

        length = length - distance
        i = i + 1
    end

    if i >= #self._distances then
        local n = #self._vertices
        return self._vertices[n-1], self._vertices[n]
    end

    local current_x, current_y = self._vertices[i*2-1], self._vertices[i*2]
    local previous_x, previous_y = self._vertices[i*2-3], self._vertices[i*2-2]

    if i == 1 then previous_x, previous_y = current_x, current_y end

    local fraction = length / self._distances[i]
    return math3d.utils.lerp(previous_x, current_x, fraction), math3d.utils.lerp(previous_y, current_y, fraction)
end

--- @brief [internal]
function rt.Spline._range(tbl, index, count)
    count = count or #tbl-index+1
    local output = {}
    for i=index, index+count-1 do
        output[#output+1] = tbl[i]
    end
    return output
end

--- @param points Table<Number>
--- @param steprate Number n steps per segment
--- @param loop Boolean
function rt.Spline._catmull_rom(points, steprate, loop)

    -- source: https://gist.github.com/HoraceBury/4afb0e68cd807d8ead220a709219db2e

    loop = which(loop, false)
    steprate = clamp(steprate, 1)

    if #points % 2 ~= 0 then
        rt.error("In rt.Spline._catmull_rom: number of point vertices have to be a multiple of 2")
    end

    if (#points < 6) then
        return points
    end

    local firstX, firstY, secondX, secondY = splat(rt.Spline._range(points, 1, 4))
    local penultX, penultY, lastX, lastY = splat(rt.Spline._range(points, #points-3, 4))

    local spline = {}
    local distances = {0}
    local total_length = 0

    local start, count = 1, #points-2
    local p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y
    local x, y

    for i = start, count, 2 do
        if i == 1 then
            p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = points[i], points[i+1], points[i], points[i+1], points[i+2], points[i+3], points[i+4], points[i+5]
        elseif i == count-1 then
            p0x, p0y, p1x, p1y, p2x, p2y = splat(rt.Spline._range(points, #points-5, 6))
            p3x, p3y = points[#points-1], points[#points]
        else
            p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = splat(rt.Spline._range(points, i-2, 8))
        end

        for t = 0, 1, 1 / steprate do
            x = 0.5 * ((2 * p1x) + (p2x - p0x) * t + (2 * p0x - 5 * p1x + 4 * p2x - p3x) * t * t + (3 * p1x - p0x - 3 * p2x + p3x) * t * t * t)
            y = 0.5 * ((2 * p1y) + (p2y - p0y) * t + (2 * p0y - 5 * p1y + 4 * p2y - p3y) * t * t + (3 * p1y - p0y - 3 * p2y + p3y) * t * t * t)

            -- prevent duplicate entries
            if (not (#spline > 0 and spline[#spline-1] == x and spline[#spline] == y)) then
                table.insert(spline, x)
                table.insert(spline, y)

                local n = #spline
                if n > 2 then
                    local x1, y1, x2, y2 = spline[n-3], spline[n-2], spline[n-1], spline[n]
                    local width, height = x2 - x1, y2 - y1
                    local distance = math.sqrt(width*width + height*height)
                    table.insert(distances, distance)
                    total_length = total_length + distance
                end
            end
        end
    end

    if loop then
        local offset = 5
        local loop_points = {}

        for x in step_range(offset * 2, 1, -1) do
            table.insert(loop_points, points[#points - (x-1)])
        end

        for x in step_range(1, offset*2, 1) do
            table.insert(loop_points, points[x])
        end

        local loop_splines = rt.Spline(loop_points, false)

        for i = 1, #loop_splines._distances do
            table.insert(spline, loop_splines._vertices[i * 2])
            table.insert(spline, loop_splines._vertices[i * 2 - 1])
            table.insert(distances, loop_splines._distances)
        end

        total_length = total_length + loop_splines._length
    end

    return spline, distances, total_length
end

--- @overload
function rt.Spline:draw()
    love.graphics.line(splat(self._vertices))
end
