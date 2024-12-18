rt.settings.spline = {
    steprate = 15, -- number of vertices per spline segment
    loop_interpolation_quality = 5, -- number of vertices used to compute the loop-closing segment
}

--- @class rt.Spline
--- @brief catmull-rom spline, c1 continuous and goes through every control point
rt.Spline = meta.new_type("Spline", rt.Drawable, function(points, loop, steprate)
    steprate = which(steprate, rt.settings.spline.steprate)
    if #points == 2 then
        points = {points[1], points[2], points[1], points[2]}
    end

    local vertices, distances, total_length = rt.Spline._catmull_rom(points, loop, steprate)
    local out = meta.new(rt.Spline, {
        _vertices = vertices,
        _distances = distances,
        _length = total_length
    })
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

    if t == 0 then
        return self._vertices[1], self._vertices[2]
    end

    if self._length == 0 then
        local n = #self._vertices
        return self._vertices[n-1], self._vertices[n]
    end

    local max_length = self._length
    local length = t * max_length

    while length > 0 and i < #self._distances do
        local distance = self._distances[i]
        if length - distance <= 0 then
            break
        end

        length = length - distance
        i = i + 1
    end

    --[[
    if i >= #self._distances then
        local n = #self._vertices
        return self._vertices[n-1], self._vertices[n]
    end
    ]]--

    local current_x, current_y = self._vertices[i*2-1], self._vertices[i*2]
    local previous_x, previous_y = self._vertices[i*2-3], self._vertices[i*2-2]

    if i == 1 then previous_x, previous_y = current_x, current_y end

    local fraction = length / self._distances[i]
    return mix(previous_x, current_x, fraction), mix(previous_y, current_y, fraction)
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
--- @param quality Number n subdivisions per vertex
function rt.Spline._catmull_rom(points, loop, quality)

    -- source: https://gist.github.com/HoraceBury/4afb0e68cd807d8ead220a709219db2e

    if loop == nil then loop = false end
    meta.assert_boolean(loop)
    loop = which(loop, false)
    local steprate = clamp(which(quality, rt.settings.spline.steprate), 1)

    if #points % 2 ~= 0 then
        rt.error("In rt.Spline._catmull_rom: number of point vertices have to be a multiple of 2")
    end

    local distances = {0}
    local total_length = 0
    local spline = {}

    local function _length_of(x1, y1, x2, y2)
        return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    end

    local p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y
    local x, y, t

    for i = 1, #points - 2, 2 do
        p0x, p0y = points[i-2] or points[i], points[i-1] or points[i+1]
        p1x, p1y = points[i], points[i+1]
        p2x, p2y = points[i+2], points[i+3]
        p3x, p3y = points[i+4] or points[i+2], points[i+5] or points[i+3]

        for t = 0, 1, 1 / steprate do
            x = 0.5 * ((2 * p1x) + (p2x - p0x) * t + (2 * p0x - 5 * p1x + 4 * p2x - p3x) * t^2 + (3 * p1x - p0x - 3 * p2x + p3x) * t^3)
            y = 0.5 * ((2 * p1y) + (p2y - p0y) * t + (2 * p0y - 5 * p1y + 4 * p2y - p3y) * t^2 + (3 * p1y - p0y - 3 * p2y + p3y) * t^3)

            if not (#spline > 0 and spline[#spline-1] == x and spline[#spline] == y) then
                table.insert(spline, x)
                table.insert(spline, y)
                if #spline > 2 then
                    local dist = _length_of(spline[#spline-3], spline[#spline-2], x, y)
                    table.insert(distances, dist)
                    total_length = total_length + dist
                end
            end
        end
    end

    if loop then
        local offset = rt.settings.spline.loop_interpolation_quality
        local loop_points = {}

        for i in step_range(offset * 2, 1, -1) do
            table.insert(loop_points, points[#points - (i-1)])
        end

        for i in step_range(1, offset*2, 1) do
            table.insert(loop_points, points[i])
        end

        local loop_spline = rt.Spline(loop_points, false)

        for i = 1, steprate * 2, 1 do

            -- replace first segment
            spline[i] = loop_spline._vertices[#(loop_spline._vertices) - (offset - 1) * (2 * steprate) + i]

            if i % 2 == 0 then
                local current = distances[i / 2]
                local next = loop_spline._distances[#(loop_spline._distances) - (offset - 1) * steprate + i / 2]
                distances[i / 2] = next
                total_length = total_length - current + next
            end

            -- replace last segment
            spline[#spline - 2 * steprate + i] = loop_spline._vertices[#loop_spline._vertices - (offset + 1) * (2 * steprate) + i]

            if i % 2 == 0 then
                local distance_i = #distances - steprate + i / 2
                local current = distances[distance_i]
                local next = loop_spline._distances[#loop_spline._distances - (offset + 1) * steprate + i / 2]
                distances[distance_i] = next
                total_length = total_length - current + next
            end
        end

        -- append final, loop-closing segment
        for i = 1, steprate * 2 do

            local vertex_i = #loop_spline._vertices - (offset + 0) * (2 * steprate) + i;
            table.insert(spline, loop_spline._vertices[vertex_i])

            if i % 2 == 0 then
                local distance = loop_spline._distances[vertex_i / 2]
                table.insert(distances, distance)
                total_length = total_length + distance
            end
        end
    end

    return spline, distances, total_length
end

--- @overload
function rt.Spline:draw()
    if not (#self._vertices > 2) then return end
    for i = 1, #self._vertices - 2, 2 do
        local x1, y1, x2, y2 = self._vertices[i], self._vertices[i+1], self._vertices[i+2], self._vertices[i+3]
        love.graphics.line(x1, y1, x2, y2)
    end
end
