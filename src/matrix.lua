rt.settings.matrix.default_value = INFINITY

--- @class rt.Matrix
--- @brief fixed-size n-dimensional matrix, stored linearly in column major order
--- @vararg dimensions
rt.Matrix = meta.new_type("Matrix", function(dimension, ...)

    local dimensions = {dimension, ...}
    local n_elements = 1
    for _, dim in pairs(dimensions) do
        if dim < 1 then rt.error("In rt.Matrix: Dimension `" .. tostring(dim) .. "` is out of range") end
        n_elements = n_elements * dim
    end

    local out =  meta.new(rt.Matrix, {
        _data = {},
        _dimensions = dimensions
    })

    for i = 1, n_elements do
        out._data[i] = INFINITY
    end

    return out
end)

--- @brief [internal]
function rt.Matrix:get_dimension(i)
    return self._dimensions[i]
end

--- @brief [internal]
function rt.Matrix:_to_linear_index(indices)

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
function rt.Matrix:set(...)

    local args = {...}

    if #args ~= #self._dimensions + 1 then
        rt.error("In rt.Matrix:set incorrect number of arguments, expected `" .. tostring(#self._dimensions) .. "` indices, one value. Got  `" .. #args .. "`")
    end

    local indices = {}

    for i = 1, #self._dimensions do
        table.insert(indices, args[i])
    end
    local value = args[#self._dimensions + 1]
    self._data[self:_to_linear_index(indices)] = value
end

--- @brief 1-based
function rt.Matrix:get(...)
    local args = {...}

    if #args ~= #self._dimensions then
        rt.error("In rt.Matrix:get incorrect number of arguments, expected `" .. tostring(#self._dimensions) .. "` indices, got `" .. #args .. "`")
    end

    return self._data[self:_to_linear_index(args)]
end

--- @brief [internal]
function rt.test.matrix()

    local x_size = 16
    local y_size = 32
    local z_size = 48

    local matrix1d = rt.Matrix(x_size)
    local matrix2d = rt.Matrix(x_size, y_size)
    local matrix3d = rt.Matrix(x_size, y_size, z_size)

    local i = 1
    for x = 1, x_size do
        matrix1d:set(x, i)
        i = i + 1
    end

    i = 1
    for x = 1, x_size do
        assert(matrix1d:get(x) == i)
        i = i + 1
    end

    i = 1
    for x = 1, x_size do
        for y = 1, y_size do
            matrix2d:set(x, y, i)
            i = i + 1
        end
    end

    i = 1
    for x = 1, x_size do
        for y = 1, y_size do
            assert(matrix2d:get(x, y) == i)
            i = i + 1
        end
    end

    i = 1
    for x = 1, x_size do
        for y = 1, y_size do
            for z = 1, z_size do
                matrix3d:set(x, y, z, i)
                i = i + 1
            end
        end
    end

    i = 1
    for x = 1, x_size do
        for y = 1, y_size do
            for z = 1, z_size do
                assert(matrix3d:get(x, y, z) == i)
                i = i + 1
            end
        end
    end
end