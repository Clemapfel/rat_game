--- @class rt.SparseMatrix
--- @brief two-dimensional sparse matrix
rt.SparseMatrix = function()
    local out = {
        _data = {
            [1] = {0}
        },
        _min_x = 1,
        _min_y = 1,
        _max_x = 1,
        _max_y = 1
    }

    local metatable = {}
    setmetatable(out, metatable)

    metatable.__tostring = function(self)
        local res = {}
        local push = function(x)
            table.insert(res, tostring(x))
        end

        push("rt.SparseMatrix {\n")
        local n_cols = self._max_x - self._min_x
        local n_rows = self._max_y - self._min_y
        for row_i = self._min_y, self._max_y, 1 do
            for col_i = self._min_x, self._max_x, 1 do
                push("\t")
                local value = self:get(col_i, row_i)
                if value == nil then
                    push("∙")
                else
                    push(value)
                end
            end
            push("\n")
        end
        push("}")
        return table.concat(res, "")
    end

    function out:set(x, y, value)
        x = math.round(x)
        y = math.round(y)
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

    --- @return min_x, max_x, min_y, max_y
    function out:get_boundaries()
        return self._min_x, self._max_x, self._min_y, self._max_y
    end
    return out
end