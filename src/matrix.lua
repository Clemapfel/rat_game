--- @class Matrix
function rt.Matrix(n_rows, n_columns, default_value)
    meta.assert_number(n_rows, n_columns)
    if meta.is_nil(default_value) then
        default_value = 0
    end

    local out = {}
    for i=1, n_rows do
        out[i] = {}
        for j=1, n_columns do
            out[i][j] = value
        end
    end
    return out
end

