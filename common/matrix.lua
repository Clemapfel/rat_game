rt.settings.matrix.default_value = 0

--- @class rt.Matrix
rt.Matrix = function(dimension, ...)
    local dimensions = {dimension, ...}
    local n_elements = 1
    for _, dim in pairs(dimensions) do
        if dim < 1 then rt.error("In rt.Matrix: Dimension `" .. tostring(dim) .. "` is out of range") end
        n_elements = n_elements * dim
    end

    local out = {
        _data = {},
        _dimensions = dimensions
    }

    for i = 1, n_elements do
        out._data[i] = rt.settings.matrix.default_value
    end

    local metatable = {}
    setmetatable(out, metatable)
    metatable.__tostring = function(self)
        local res = {}
        local push = function(x)
            table.insert(res, tostring(x))
        end

        push("rt.Matrix(")
        for i = 1, #self._dimensions do
            push(tostring(self._dimensions[i]))
            if i ~= #self._dimensions then
                push("x")
            end
        end
        push(", {\n")

        for j = 1, self._dimensions[1] do
            push("\t")
            for i = 1, self._dimensions[2] do
                push(tostring(self:get(i, j)) .. " ")
            end
            push("\n")
        end
        push("}")
        return table.concat(res)
    end

    --- @brief [internal]
    function out:get_dimension(i)
        return self._dimensions[i]
    end

    --- @brief [internal]
    function out:_to_linear_index(indices)

        if #indices ~= #self._dimensions then
            rt.error("In rt.Matrix: incorrect number of indices `" .. tostring(#indices)  .. "` for a matrix of rank `" .. tostring(#self._dimensions) .. "`")
        end

        for i, index in ipairs(indices) do
            if index > self:get_dimension(i) then
                rt.error("In rt.Matrix: index `" .. tostring(index) .. "` is out of bounds for a matrix with size `" .. tostring(self:get_dimension(i)) .. "` in dimension `" .. i .. "`")
            end
        end

        -- source: https://github.com/Clemapfel/jluna/blob/master/.src/array.inl#L265
        local index = 1;
        local mul = 1;

        for i = 1, #self._dimensions do
            index = index + (indices[i] - 1) * mul  -- 1-based to 0-based
            mul = mul * self:get_dimension(i)
        end

        return index
    end

    --- @brief 1-based
    function out:set(...)

        local args = {...}
        if #args == 2 then
            -- linear indexing

            local i = args[1]
            local value = args[2]

            if i > #self._data then
                rt.error("In rt.Matrix:set: linear index `" .. i .. "` is out of bounds for a matrix of size `" .. #self._data .. "`")
            end

            self._data[i] = value
            return
        end

        if #args ~= #self._dimensions + 1 then
            rt.error("In rt.Matrix:set: incorrect number of arguments, expected `" .. tostring(#self._dimensions) .. "` indices, one value. Got  `" .. #args .. "`")
        end

        local indices = {}
        for i = 1, #self._dimensions do
            table.insert(indices, args[i])
        end
        local value = args[#self._dimensions + 1]
        self._data[self:_to_linear_index(indices)] = value
    end

    --- @brief 1-based
    function out:get(...)
        local args = {...}

        if #args ~= #self._dimensions then
            rt.error("In rt.Matrix:get incorrect number of arguments, expected `" .. tostring(#self._dimensions) .. "` indices, got `" .. #args .. "`")
        end

        return self._data[self:_to_linear_index(args)]
    end

    --- @brief replace all values
    function out:clear(value)
        for i = 1, #self._data do
            self._data[i] = value
        end

        self._min = value
        self._max = value
    end

    return out
end

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