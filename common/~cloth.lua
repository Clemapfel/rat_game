--- ###

rt.Cloth = meta.new_type("Cloth", function(width, height, n_columns, n_rows, anchor_x, anchor_y)

    local n_distance_x = math.floor(width / n_columns)
    local node_distance_y = math.floor(height / n_rows)

    return meta.new(rt.Cloth, {
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
        _colors = {},
        _masses = {},

        _gravity_x = 0,
        _gravity_y = 1000,

        _grid_i_to_node_i = {{}},

        _mesh = {}, -- rt.Mesh
        _vertices = {},

        _was_cut = {}
    })
end)

function rt.Cloth:realize()

    self._positions = {}
    self._old_positions = {}
    self._pairs = {}
    self._colors = {}

    local start_x, start_y = love.mouse.getPosition()
    local current_x, current_y = start_x, start_y
    local max_mass = 10
    self._n_nodes = self._n_nodes_per_column * self._n_nodes_per_row
    self._n_pairs = 0

    local vertices = {}

    local row_i = 1
    local col_i = 1
    for i = 1, self._n_nodes do
        table.insert(self._positions, {current_x, current_y})
        table.insert(self._old_positions, {current_x, current_y})

        self._grid_i_to_node_i[col_i][row_i] = i
        table.insert(self._masses, (row_i + 1) / self._n_rows * 2)
        current_y = current_y + self._node_distance_y

        local color = rt.hsva_to_rgba(rt.HSVA(i / self._n_nodes, 1, 1, 1));
        table.insert(vertices, {
            current_x, current_y,
            (col_i - 1) / (self._n_columns - 1), (row_i - 1) / (self._n_rows - 1),
            1, 1, 1, 1--color.r, color.g, color.b, 1
        })

        if i < self._n_nodes and row_i ~= self._n_nodes_per_column then
            table.insert(self._pairs, {i, i + 1})
            self._n_pairs = self._n_pairs + 1
        end

        if i > self._n_nodes_per_column then
            table.insert(self._pairs, {i, i - self._n_nodes_per_column})
            self._n_pairs = self._n_pairs + 1
        end

        if row_i >= self._n_nodes_per_column then
            row_i = 0
            col_i = col_i + 1
            current_x = current_x + self._node_distance_x
            current_y = start_y
            table.insert(self._grid_i_to_node_i, {})
        end

        row_i = row_i + 1
    end

    for i = 1, self._n_pairs do
        table.insert(self._colors, {
            rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(i / self._n_pairs, 1, 1, 1)))
        })
    end


    local vertex_map = {}
    for col_i = 1, self._n_columns do
        for row_i = 1, self._n_rows - 1 do
            table.insert(vertex_map, self._grid_i_to_node_i[col_i][row_i])
            table.insert(vertex_map, self._grid_i_to_node_i[col_i + 1][row_i])
            table.insert(vertex_map, self._grid_i_to_node_i[col_i][row_i+1])

            table.insert(vertex_map, self._grid_i_to_node_i[col_i + 1][row_i])
            table.insert(vertex_map, self._grid_i_to_node_i[col_i][row_i + 1])
            table.insert(vertex_map, self._grid_i_to_node_i[col_i + 1][row_i + 1])
        end
    end

    self._vertices = vertices
    self._mesh = love.graphics.newMesh(vertices, rt.MeshDrawMode.TRIANGLES, rt.SpriteBatchUsage.DYNAMIC)
    self._mesh:setVertexMap(vertex_map)

    self._is_realized = true
end

function rt.Cloth:draw()
    if self._is_realized ~= true then return end
    local positions = self._positions
    local colors = self._colors

    --love.graphics.setLineWidth(3)
    --love.graphics.setPointSize(3)

    love.graphics.draw(self._mesh)

    --[[
    local pair_i = 1
    local n = self._n_pairs
    for i = 1, n, 1 do
        local pair = self._pairs[i]

        local node_1_i = pair[1]
        local node_2_i = pair[2]

        local node_1_x, node_1_y = self._positions[node_1_i][1], self._positions[node_1_i][2]
        local node_2_x, node_2_y = self._positions[node_2_i][1], self._positions[node_2_i][2]

        local color = self._colors[i]
        love.graphics.setColor(table.unpack(color))
        love.graphics.line(node_1_x, node_1_y, node_2_x, node_2_y)
    end
    ]]--

    for _, pair in pairs(self._pairs) do
        local node_1_i = pair[1]
        local node_2_i = pair[2]

        if not (self._was_cut[node_1_i] or self._was_cut[node_2_i]) then

            local node_1_x, node_1_y = self._positions[node_1_i][1], self._positions[node_1_i][2]
            local node_2_x, node_2_y = self._positions[node_2_i][1], self._positions[node_2_i][2]

            love.graphics.line(node_1_x, node_1_y, node_2_x, node_2_y)
        end
    end
end

function rt.Cloth:update(delta, n_iterations)
    local friction = 1
    local gravity_x = self._gravity_x
    local gravity_y = self._gravity_y
    local delta_squared = delta * delta


    clock = rt.Clock()

    -- verlet step
    local positions = self._positions
    local old_positions = self._old_positions
    local masses = self._masses

    local n = self._n_nodes
    for i = 1, n do
        local current_x, current_y = positions[i][1], positions[i][2]
        local old_x, old_y = old_positions[i][1], old_positions[i][2]
        local mass = masses[i]

        local before_x, before_y = current_x, current_y

        positions[i][1] = current_x + (current_x - old_x) * friction + mass * gravity_x * delta_squared
        positions[i][2] = current_y + (current_y - old_y) * friction + mass * gravity_y * delta_squared

        old_positions[i][1] = before_x
        old_positions[i][2] = before_y
    end

    dbg("01 ", clock:restart():as_seconds() / (1 / 60))

    local sqrt = math.sqrt
    local node_distance = self._node_distance_x
    local n = self._n_pairs

    -- TODO
    local x, y = love.mouse.getPosition()
    -- TODO


    -- apply constraints
    for _ = 1, n_iterations do
        local o = 100

        local w = 2 * self._width
        for i = 1, self._n_columns do
            local pos = self._positions[self._grid_i_to_node_i[i][1]]
            pos[1] = x - (i / self._n_columns / 2) * w
            pos[2] = y
        end

        --self._positions[self._grid_i_to_node_i[1][1]] = {x - 0.4 * self._width - o, y - o}
        --self._positions[self._grid_i_to_node_i[math.floor(self._n_nodes_per_row / 2) + 1][1]] = {x, y - 3 * o}
        --self._positions[self._grid_i_to_node_i[self._n_nodes_per_row][1]] = {x + 0.4 * self._width + o, y - o}


        --self._positions[self._grid_i_to_node_i[1][self._n_columns]] = {x - 0.3 * self._width, y + self._height}
        --self._positions[self._grid_i_to_node_i[math.floor(self._n_nodes_per_row / 2) + 1][self._n_columns]] = {x, y + self._height}
        --self._positions[self._grid_i_to_node_i[self._n_nodes_per_row][self._n_columns]] = {x + 0.3 * self._width, y + self._height}

        --self._positions[self._grid_i_to_node_i[1][1]] = {x - 0.2 * self._width, y}
        --self._positions[self._grid_i_to_node_i[math.floor(self._n_nodes_per_row / 2) + 1][1]] = {x, y}
        --self._positions[self._grid_i_to_node_i[self._n_nodes_per_row][1]] = {x + 0.2 * self._width, y}

        for _, pair in pairs(self._pairs) do
            --local pair = self._pairs[i]

            local node_1_i, node_2_i = pair[1], pair[2]

            local node_1_x, node_1_y = positions[node_1_i][1], positions[node_1_i][2]
            local node_2_x, node_2_y = positions[node_2_i][1], positions[node_2_i][2]

            local difference_x = node_1_x - node_2_x
            local difference_y = node_1_y - node_2_y

            local distance
            local x_delta = node_2_x - node_1_x
            local y_delta = node_2_y - node_1_y
            distance = sqrt(x_delta * x_delta + y_delta * y_delta)

            local difference = (node_distance - distance) / distance

            local translate_x = difference_x * 0.5 * difference
            local translate_y = difference_y * 0.5 * difference

            positions[node_1_i][1] = node_1_x + translate_x
            positions[node_1_i][2] = node_1_y + translate_y
            positions[node_2_i][1] = node_2_x - translate_x
            positions[node_2_i][2] = node_2_y - translate_y
        end
    end

    dbg("02 ", clock:restart():as_seconds() / (1 / 60))
    for i = 1, self._n_nodes do
        self._vertices[i][1] = positions[i][1]
        self._vertices[i][2] = positions[i][2]
    end
    self._mesh:setVertices(self._vertices)
    dbg("03 ", clock:restart():as_seconds() / (1 / 60))
end
