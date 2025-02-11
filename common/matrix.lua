--- @class rt.Matrix
rt.Matrix = meta.new_type("Matrix", function()
    return meta.new(rt.Matrix, {
        _data = {},
        _min_x = 0,
        _min_y = 0,
        _max_x = 0,
        _max_y = 0,
        _index_range_update_needed = true
    })
end)

meta.get_instance_metatable(rt.Matrix).__tostring = function(self)
    if self._index_range_update_needed then self:_update_index_range() end

    local out = {}
    for x = self._min_x, self._max_x, 1 do
        for y = self._min_y, self._max_y, 1 do
            local value = self:get(x, y)
            if value == nil then
                table.insert(out, "   ")
            else
                local prefix = ""
                if value < 100 then prefix = 0 .. prefix end
                if value <  10 then prefix = 0 .. prefix end
                table.insert(out, prefix .. value)
            end
            table.insert(out, " ")
        end
        table.insert(out, "\n")
    end
    return table.concat(out)
end

function rt.Matrix:get(x, y)
    local column = self._data[x]
    if column == nil then return nil end
    return column[y]
end

function rt.Matrix:set(x, y, value)
    local column = self._data[x]
    if column == nil then
        column = {}
        self._data[x] = column
    end
    column[y] = value
    self._index_range_update_needed = true
end

local _min, _max = math.min, math.max

--- @return (Number, Number, Number, Number) min_x, min_y, max_x, max_y
function rt.Matrix:get_index_range()
    if self._min_update_needed then
        self:_update_index_range()
    end

    return self._min_x, self._min_y, self._max_x, self._max_y
end

function rt.Matrix:_update_index_range()
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