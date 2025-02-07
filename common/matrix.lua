--- @class rt.Matrix
rt.Matrix = meta.new_type("Matrix", function()
    return meta.new({
        _data = {},
        _min_x = 0,
        _min_y = 0,
        _max_x = 0,
        _max_y = 0,
        _index_range_update_needed = true
    })
end)

function rt.Matrix:get(x, y)
    local column = self._data[x]
    if column == nil then return nil end
    return column[y]
end

function rt.Matrix:set(x, y, value)
    local column = self._data[x]
    if column == nil then
        column = {}
        self._data = column
    end
    column[y] = value
    self._index_range_update_needed = true
end

local _min, _max = math.min, math.max

--- @return (Number, Number, Number, Number) min_x, min_y, max_x, max_y
function rt.Matrix:get_index_range()
    if self._min_update_needed then
        local min_x, min_y = POSITIVE_INFINITY, POSITIVE_INFINITY
        local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY
        for y, column in pairs(self._data) do
            for x, _ in pairs(column) do
                min_x = _min(min_x, x)
                max_x = _max(max_x, x)
            end
            min_y = _min(min_y, y)
            max_y = _max(max_y, y)
        end
        self._min_x = min_x
        self._min_y = min_y
        self._max_x = max_x
        self._max_y = max_y
        self._index_range_update_needed = false
    end

    return self._min_x, self._min_y, self._max_x, self._max_y
end