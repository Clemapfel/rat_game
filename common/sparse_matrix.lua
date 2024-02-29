--- @class rt.SparseMatrix
--- @brief two-dimensional sparse matrix
rt.SparseMatrix = function()
    local out = {
        _data = {
            [0] = {0}
        },
        _min_x = 0,
        _min_y = 0,
        _max_x = 0,
        _max_y = 0
    }

    local metatable = {}
    setmetatable(out, metatable)

    function out:set(x, y, value)
        if self._data[y] == nil then
            self._data[y] = {}
        end
        self._data[y][x] = value

        self._min_x = math.min(x, self._min_x)
        self._max_x = math.max(x, self._max_x)
        self._min_y = math.min(y, self._min_y)
        self._max_y = math.max(y, self._max_y)
    end

    function out:get(x, y)
        if self._data[y] == nil then
            return nil
        else
            return self._data[y][x]
        end
    end

    function out:clear(_)
        meta.assert_nil(_)
        self._data = {
            [0] = {0}
        }
        self._min_x = 0
        self._min_y = 0
        self._max_x = 0
        self._max_y = 0
    end

    return out
end