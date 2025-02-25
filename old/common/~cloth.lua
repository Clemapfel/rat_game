--- @class rt.Cloth
rt.Cloth = meta.new_type("Cloth", function(width, height, n)

    local node_distance = math.sqrt(width * height / n)
    local n_columns = math.ceil(width / node_distance)
    local n_rows = math.ceil(height / node_distance)

    return meta.new(rt.Cloth, {
        _is_realized = false,

        _width = width,
        _height = height,
        _node_distance = node_distance,
        _n_nodes_per_row = n_columns,
        _n_rows = n_rows,
        _n_nodes_per_column = n_rows,
        _n_columns = n_columns,

        _positions = {},
        _old_positions = {},
        _pairs = {},
        _grid_i_to_node_i = {{}},

        _gravity_x = 0,
        _gravity_y = 100,

        _mesh = {},
        _vertices = {},
    })
end)

--- @brief
function rt.Cloth:realize()
    self._positions = {}
    self._old_positions = {}
    self._masses = {}
    self._pairs = {}
    self._grid_i_to_node_i = {{}}
    self._grid_i_to_vertex_i = {{}}

    local start_x, start_y = love.mouse.getPosition()
    local current_x, current_y = start_x, start_y
    local max_mass = 10
    self._n_nodes = self._n_nodes_per_column * self._n_nodes_per_row
    self._n_pairs = 0

    local vertices = {}
    local row_i, col_i = 1, 1
    local node_i = 1
    for i = 1, self._n_nodes do
        table.insert(self._positions, current_x)
        table.insert(self._positions, current_y)

        table.insert(self._old_positions, current_x)
        table.insert(self._old_positions, current_y)

        local mass = row_i
        table.insert(self._masses, mass)
        table.insert(self._masses, mass) -- twice for faster access in update

        self._grid_i_to_node_i[col_i][row_i] = node_i
        self._grid_i_to_vertex_i[col_i][row_i] = i

        current_y = current_y + self._node_distance

        local color = rt.hsva_to_rgba(rt.HSVA(
        self._grid_i_to_vertex_i[col_i][row_i] / self._n_nodes,
            0,
            rt.gaussian_bandpass(col_i / self._n_columns) + 0.3
        ))

        table.insert(vertices, {
            current_x, current_y,
            (col_i - 1) / (self._n_columns - 1), (row_i - 1) / (self._n_rows - 1),
            1, 1, 1, 1--color.r, color.g, color.b, color.a
        })

        if i < self._n_nodes and row_i ~= self._n_nodes_per_column then
            table.insert(self._pairs, node_i)
            table.insert(self._pairs, node_i + 2)
            self._n_pairs = self._n_pairs + 1
        end

        if i > self._n_nodes_per_column then
            table.insert(self._pairs, node_i)
            table.insert(self._pairs, node_i - self._n_nodes_per_column * 2)
            self._n_pairs = self._n_pairs + 1
        end

        if row_i >= self._n_nodes_per_column then
            row_i = 0
            col_i = col_i + 1
            current_x = current_x + self._node_distance
            current_y = start_y
            table.insert(self._grid_i_to_node_i, {})
            table.insert(self._grid_i_to_vertex_i, {})
        end

        row_i = row_i + 1
        node_i = node_i + 2
    end

    local vertex_map = {}
    for col_i = 1, self._n_columns do
        for row_i = 1, self._n_rows - 1 do
            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i][row_i])
            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i + 1][row_i])
            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i][row_i+1])

            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i + 1][row_i])
            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i][row_i + 1])
            table.insert(vertex_map, self._grid_i_to_vertex_i[col_i + 1][row_i + 1])
        end
    end

    self._vertices = vertices
    self._mesh = love.graphics.newMesh(vertices, rt.MeshDrawMode.TRIANGLES, rt.GraphicsBufferUsage.DYNAMIC)
    self._mesh:setVertexMap(vertex_map)

    self._is_realized = true
end

--- @override
function rt.Cloth:draw()
    if self._is_realized ~= true then return end
    --love.graphics.setWireframe(true)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._mesh)
    --love.graphics.setWireframe(false)
end

--- @override
function rt.Cloth:update(delta, n_iterations)
    local friction = 1
    local gravity_x = self._gravity_x
    local gravity_y = self._gravity_y
    local delta_squared = delta * delta

    -- verlet step
    local positions = self._positions
    local old_positions = self._old_positions
    local pairs = self._pairs
    local masses = self._masses

    local n = 2 * (self._n_nodes - 1)
    for i = 1, n, 2 do
        local x_i, y_i = i, i + 1
        local current_x, current_y = positions[x_i], positions[y_i]
        local old_x, old_y = old_positions[x_i], old_positions[y_i]
        local mass = masses[x_i]
        local before_x, before_y = current_x, current_y

        positions[x_i] = current_x + (current_x - old_x) * friction + mass * gravity_x * delta_squared
        positions[y_i] = current_y + (current_y - old_y) * friction + mass * gravity_y * delta_squared

        old_positions[x_i] = before_x
        old_positions[y_i] = before_y
    end

    -- TODO
    local x, y = love.mouse.getPosition()
    -- TODO

    CURTAIN_WIDTH = 500
    -- apply constraints
    for _ = 1, n_iterations do

        do
            local x, y = love.mouse.getPosition()
            x = x - 0.5 * CURTAIN_WIDTH
            local step = CURTAIN_WIDTH / self._n_columns
            for j = 1, self._n_columns do
                local i = self._grid_i_to_node_i[j][1]
                positions[i] = x
                positions[i + 1] = y
                x = x + step
            end
        end

        local sqrt = math.sqrt
        local node_distance = self._node_distance
        n = 2 * self._n_pairs
        for pair_i = 1, n, 2  do
            local node_1_i, node_2_i = pairs[pair_i], pairs[pair_i + 1]
            local node_1_x, node_1_y = positions[node_1_i], positions[node_1_i + 1]
            local node_2_x, node_2_y = positions[node_2_i], positions[node_2_i + 1]

            local difference_x = node_1_x - node_2_x
            local difference_y = node_1_y - node_2_y

            local distance
            local x_delta = node_2_x - node_1_x
            local y_delta = node_2_y - node_1_y
            distance = sqrt(x_delta * x_delta + y_delta * y_delta)

            local difference = (node_distance - distance) / distance

            local translate_x = difference_x * 0.5 * difference
            local translate_y = difference_y * 0.5 * difference

            positions[node_1_i] = node_1_x + translate_x
            positions[node_1_i + 1] = node_1_y + translate_y
            positions[node_2_i] = node_2_x - translate_x
            positions[node_2_i + 1] = node_2_y - translate_y
        end
    end

    -- update mesh
    n = 2 * self._n_nodes
    for i = 1, n, 2 do
        self._vertices[(i + 1) / 2][1] = positions[i]
        self._vertices[(i + 1) / 2][2] = positions[i + 1]
    end
    self._mesh:setVertices(self._vertices)
end
