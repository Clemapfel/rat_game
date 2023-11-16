--- @class rt.Matrix
function rt.Matrix(n_rows, n_columns)
    meta.assert_number(n_rows, n_columns)

    local out = meta.new(rt.Matrix, {
        _elements = {}
    })
    for i=1, n_rows do
        out._elements[i] = {}
        for j=1, n_columns do
            out._elements[i][j] = {}
        end
    end
    return out
end





