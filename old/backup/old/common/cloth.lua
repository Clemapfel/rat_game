--[[
--- @class rt.Cloth
rt.Cloth = meta.new_type("Cloth", function(width, height, n_columns, n_rows)
    return meta.new(rt.Cloh, {
        _is_realized = false,

        _width = width,
        _height = height,
        _node_distance_x = math.min(width / n_columns, height / n_rows),
        _node_distance_y = math.min(width / n_columns, height / n_rows),
        _n_nodes_per_row = n_columns,
        _n_rows = n_rows,
        _n_nodes_per_column = n_rows,
        _n_columns = n_columns,

        _positions = {},
        _old_positions = {},
        _pairs = {},

        _gravity_x = 0,
        _gravity_y = 100,

        _grid_i_to_node_i = {{}},

        _mesh = {}, -- rt.Mesh
        _vertices = {}
    })
end)

--- @brief
function rt.Cloth:realize()
    self._positions = {}
    self._old_positions = {}
    self._pairs = {}
    self._vertices = {}

    local start_x, start_y = 0, 0
    local current_x, current_y = start_x, start_y

    local row_i, col_i = 1, 1
    for i = 1, self._n_nodes do

        table.insert(self._positions, current_x)
        table.insert(self._positions, current_y)

        table.insert(self._old_positions, current_x)
        table.insert(self._old_positions, current_x)
    end
end

]]--