--- @class rt.Path
rt.Path = meta.new_type("Path", function(points, ...)
    if meta.is_number(points) then points = {points, ...} end
    local n_points = sizeof(points)
    if n_points % 2 ~= 0 then rt.error("In rt.Path: number of point coordinates is not a multiple of two") end

    local out = meta.new(rt.Path, {
        _points = points,
        _distances = {},
        _n_points = n_points,
        _first_distance = 0,
        _last_distance = 0
    })
    out:_update()
    return out
end)

do
    local _sqrt = math.sqrt -- upvalues for optimization
    local _insert = table.insert
    local _atan2, _sin, _cos = math.atan2, math.sin, math.cos
    local _advance = function(x, y, angle, fraction, distance)
        local delta = fraction * distance
        return x + delta * _cos(angle), y + delta * _sin(angle)
    end

    --- @brief
    function rt.Path:_update()
        self._fraction_to_node = {}
        local distances = {}

        local points = self._points
        local n = self._n_points
        local distance_sum = 0
        local n_entries = 0

        local first_distance, last_distance

        for i = 1, n - 2, 2 do
            local x1, y1 = self._points[i+0], self._points[i+1]
            local x2, y2 = self._points[i+2], self._points[i+3]

            local distance = _sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))

            if first_distance == nil then first_distance = distance end
            last_distance = distance

            local slope = (y2 - y1) / (x2 - x1)
            local to_insert = {
                from_x = x1,
                from_y = y1,
                angle = _atan2(y2 - y1, x2 - x1),
                distance = distance,
                cumulative_distance = distance_sum
            }
            _insert(distances, to_insert)
            distance_sum = distance_sum + distance
            n_entries = n_entries + 1
        end

        self._first_distance = first_distance
        self._last_distance = last_distance

        local fraction = 0
        local length = distance_sum
        for entry_i = 1, n_entries do
            local entry = distances[entry_i]
            entry.fraction = entry.cumulative_distance / length
        end

        for entry_i = 1, n_entries do
            local current = distances[entry_i]
            local next = distances[entry_i + 1]

            if entry_i < n_entries then
                current.fraction_length = next.fraction - current.fraction
            else
                current.fraction_length = 1 - current.fraction
            end
        end
        self._entries = distances
        self._n_entries = n_entries
        self._length = distance_sum
    end

    --- @brief
    function rt.Path:at(t)
        local n_entries = self._n_entries
        local entries = self._entries

        if t > 1 then t = 1 end
        local closest_entry
        for i = 1, n_entries - 1 do
            if entries[i].fraction <= t and entries[i + 1].fraction >= t then
                closest_entry = entries[i]
                break
            end
        end
        if closest_entry == nil then closest_entry = entries[n_entries] end

        return _advance(
            closest_entry.from_x,
            closest_entry.from_y,
            closest_entry.angle,
            (t - closest_entry.fraction) / closest_entry.fraction_length,
            closest_entry.distance
        )
    end
end

--- @brief
function rt.Path:draw()
    love.graphics.line(self._points)
end