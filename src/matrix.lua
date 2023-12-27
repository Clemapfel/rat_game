rt.settings.matrix.default_value = INFINITY

--- @class rt.Matrix
--- @vararg dimensions
rt.Matrix2d = meta.new_type("Matrix", function(width, height)

    for _, dim in pairs({dimension, ...}) do
        if dim < 1 then rt.error("In rt.Matrix: Dimension `" .. tostring(dim) .. "` is out of range") end
    end

    local out =  meta.new(rt.Matrix, {
        data = {},
        dimension = {width, height}
    })

    local dims = {dimension, ...}
    for x = 1, width do
        for y = 1, height do
            if meta.is_nil(out.data[x]) then out.data[x] = {} end
            out.data[out._to_linear_index(x, y)] = INFINITY
        end
    end

    return out
end)

--- @brief
function rt.Matrix._from_linear_index(i)
    std::array<uint64_t, R> indices = {uint64_t(in)...};
    uint64_t index = 0;
    uint64_t mul = 1;

    for (uint64_t i = 0; i < R; ++i)
    {
    index += (indices.at(i)) * mul;
    uint64_t dim = get_dimension(i);
    mul *= dim;
    }

    return operator[]<T>(index);
end

--- @brief
function rt.Matrix._to_linear_index(x, y, x_dimension, y_dimension)
    for i = 0,
end
---
function rt.Matrix:set(...)

end