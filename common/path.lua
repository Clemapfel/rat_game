--- @class rt.Path
--- @brief arc-length parameterized chain of line segments, unlike spline, extremely fast to evaluate
rt.Path = meta.new_type("Path", function(points, ...)
    if meta.is_number(points) then
        points = {points, ...}
    end

    local out = meta.new(rt.Path, {
        _points = points,
        _distances = {},
        _n_points = 0,
        _first_distance = 0,
        _last_distance = 0
    })
    out:create_from(points, ...)
    return out
end)

do
    local _sqrt = math.sqrt -- upvalues for optimization
    local _insert = table.insert
    local _atan2, _sin, _cos = math.atan2, math.sin, math.cos
    local _floor, _ceil = math.floor, math.ceil

    --- @brief
    function rt.Path:_update()
        local distances = {}
        local points = self._points
        local n = self._n_points
        local total_length = 0
        local n_entries = 0

        local first_distance, last_distance

        for i = 1, n - 2, 2 do
            local x1, y1 = self._points[i+0], self._points[i+1]
            local x2, y2 = self._points[i+2], self._points[i+3]

            local distance = _sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
            local slope = (y2 - y1) / (x2 - x1)
            local to_insert = {
                from_x = x1,
                from_y = y1,
                angle = _atan2(y2 - y1, x2 - x1),
                distance = distance,
                cumulative_distance = total_length,
                fraction = nil,
                fraction_length = nil
            }
            _insert(distances, to_insert)
            total_length = total_length + distance
            n_entries = n_entries + 1
        end

        if n_entries == 1 then
            local entry = distances[1]
            entry.fraction = 0
            entry.fraction_length = 1
        else
            for i = 1, n_entries - 1 do
                local current = distances[i]
                local next = distances[i + 1]

                current.fraction = current.cumulative_distance / total_length
                next.fraction = next.cumulative_distance / total_length
                current.fraction_length = next.fraction - current.fraction

                if i == 1 then self._first_distance = current.fraction end
                if i == n_entries - 1 then self._last_distance = next.fraction end
            end

            do
                local last = distances[n_entries]
                last.fraction_length = 1 - last.fraction
            end
        end

        self._entries = distances
        self._n_entries = n_entries
        self._length = total_length
    end

    --- @brief
    function rt.Path:at(t)
        local n_entries = self._n_entries
        local entries = self._entries

        if t > 1 then t = 1 end
        local closest_entry
        if t <= self._first_distance then
            closest_entry = entries[1]
        elseif t >= self._last_distance then
            closest_entry = entries[n_entries]
        else
            -- binary search for closest fraction
            local low = 1
            local high = n_entries
            while low <= high do
                local mid = _ceil((low + high) / 2)
                closest_entry = entries[mid]
                local right = entries[mid + 1]
                if right == nil or (closest_entry.fraction <= t and right.fraction >= t) then
                    break
                elseif closest_entry.fraction < t then
                    low = mid + 1
                elseif closest_entry.fraction > t then
                    high = mid - 1
                    TODO: which does this deadllcok
                end
            end
        end

        -- translate point along line from current to next entry
        local delta = (t - closest_entry.fraction) / closest_entry.fraction_length * closest_entry.distance
        return closest_entry.from_x + delta * _cos(closest_entry.angle),
            closest_entry.from_y + delta * _sin(closest_entry.angle)
    end
end

--- @brief
function rt.Path:create_from(points, ...)
    if meta.is_number(points) then points = {points, ...} end
    local n_points = sizeof(points)
    if n_points % 2 ~= 0 then rt.error("In rt.Path: number of point coordinates is not a multiple of two") end
    self._n_points = n_points
    self:_update()
end

--- @brief
function rt.Path:list_points()
    local out = {}
    for i = 1, #self._points, 2 do
        table.insert(out, {self._points[i], self._points[i+1]})
    end
    return out
end

--- @brief
function rt.Path:draw()
    love.graphics.line(self._points)
end