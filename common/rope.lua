--- @class Rope
rt.Rope = meta.new_type("Rope", function(length, n_nodes, anchor_x, anchor_y)
    meta.assert_number(length, n_nodes, anchor_x, anchor_y)
    return meta.new(rt.Rope, {
        _is_realized = false,
        _n_nodes = n_nodes + 1,
        _node_distance = length / n_nodes,

        _friction = 0.02,    -- [0, 1], 1 maximum friction, 0 no friction
        _positions = {},     -- Table<Number> (size 2 * n)
        _old_positions = {}, -- Table<Number> (size 2 * n)
        _masses = {},        -- Table<Number> (size n)

        _gravity_x = 0,
        _gravity_y = 1000,

        _anchor_x = anchor_x,
        _anchor_y = anchor_y,
        _anchor_angle = (90 / 360) * (2 * math.pi),

        _colors = {}
    })
end)

--- @brief
function rt.Rope:realize()
    local x, y = self._anchor_x, self._anchor_y

    self._positions = {}
    self._old_positions = {}
    self._masses = {}

    local mass_distribution = function(x)
        assert(x >= 0 and x <= 1)
        --return clamp(x, 0.5, 1)
        --return 1
        return 1 - x
        --return math.exp(-(4 * (x - 0.5))^2)
    end

    local max_mass = 1
    for i = 1, self._n_nodes do
        table.insert(self._positions, x)
        table.insert(self._positions, y)
        table.insert(self._old_positions, x)
        table.insert(self._old_positions, y)
        table.insert(self._masses, mass_distribution((self._n_nodes - i) / self._n_nodes) * max_mass)

        y = y + self._node_distance
    end

    -- pre-calculate colors
    for i = 1, 2 * self._n_nodes, 2 do
        local node_x = self._positions[i]
        local node_y = self._positions[i+1]
        local color = rt.hsva_to_rgba(rt.HSVA(self._masses[(i + 1) / 2] / max_mass, 1, 1, 1))
        self._colors[i] = {color.r, color.g, color.b, color.a}
    end

    self._is_realized = true
end

--- @brief
function rt.Rope:draw()
    if self.is_realized == false then return end

    love.graphics.setLineWidth(3)
    local n = 2 * (self._n_nodes - 1)
    for i = 1, n, 2 do
        local node_1_x, node_1_y = self._positions[i], self._positions[i + 1]
        local node_2_x, node_2_y = self._positions[i + 2], self._positions[i + 3]

        local color = self._colors[i]
        love.graphics.setColor(table.unpack(color))
        love.graphics.line(node_1_x, node_1_y, node_2_x, node_2_y)
    end
end

--- @brief
function rt.Rope:update(delta, n_iterations)
    if self._is_realized ~= true then return end
    n_iterations = which(n_iterations, 80)
    self:_verlet_step(delta)
    local anchor_x, anchor_y = self._anchor_x, self._anchor_y
    for i = 1, n_iterations do
        local mouse_x, mouse_y = love.mouse.getPosition()
        self._positions[1] = anchor_x
        self._positions[2] = anchor_y
        self:_apply_jakobsen_constraints()
    end
end

--- @brief
function rt.Rope:_verlet_step(delta)
    local delta_squared = delta * delta
    local gravity_x, gravity_y = self._gravity_x, self._gravity_y
    local n = 2 * self._n_nodes
    local positions = self._positions
    local old_positions = self._old_positions
    local masses = self._masses
    local friction = clamp(1 - self._friction, 0, 1)
    for i = 1, n, 2 do
        local current_x, current_y = positions[i], positions[i+1]
        local old_x, old_y = old_positions[i], old_positions[i+1]
        local mass = masses[(i + 1) / 2]

        local before_x, before_y = current_x, current_y

        positions[i] = current_x + (current_x - old_x) * friction + gravity_x * mass * delta_squared
        positions[i+1] = current_y + (current_y - old_y) * friction + gravity_y * mass * delta_squared

        old_positions[i] = before_x
        old_positions[i+1] = before_y
    end
end

--- @brief
function rt.Rope:_apply_jakobsen_constraints()
    -- src: https://github.com/Toqozz/blog-code/blob/master/rope/Assets/Rope.cs
    -- src: https://www.owlree.blog/posts/simulating-a-rope.html

    local sqrt = math.sqrt
    local node_distance = self._node_distance
    local n = 2 * (self._n_nodes - 1)
    local positions = self._positions

    for i = 1, n, 2 do
        local node_1_xi, node_1_yi, node_2_xi, node_2_yi = i, i+1, i+2, i+3
        local node_1_x, node_1_y = positions[node_1_xi], positions[node_1_yi]
        local node_2_x, node_2_y = positions[node_2_xi], positions[node_2_yi]

        local difference_x = node_1_x - node_2_x
        local difference_y = node_1_y - node_2_y

        local distance
        local x_delta = node_2_x - node_1_x
        local y_delta = node_2_y - node_1_y
        distance = sqrt(x_delta * x_delta + y_delta * y_delta)

        local difference = (node_distance - distance) / distance

        local translate_x = difference_x * 0.5 * difference
        local translate_y = difference_y * 0.5 * difference

        positions[node_1_xi] = node_1_x + translate_x
        positions[node_1_yi] = node_1_y + translate_y
        positions[node_2_xi] = node_2_x - translate_x
        positions[node_2_yi] = node_2_y - translate_y
    end
end

--- @brief
function rt.Rope:relax()
    for i = 1, 2 * self._n_nodes, 2 do
        self._old_positions[i] = self._positions[i]
        self._old_positions[i+1] = self._positions[i+1]
    end
end

--- @brief
function rt.Rope:set_anchor(x, y)
    self._anchor_x = x
    self._anchor_y = y
end

--- @brief
function rt.Rope:set_gravity(x, y)
    self._gravity_x = x
    self._gravity_y = y
end

--- ###

rt.Cloth = meta.new_type("Cloth", function(width, height, n_columns, n_rows, anchor_x, anchor_y)

    local n_distance_x = math.floor(width / n_columns)
    local node_distance_y = math.floor(height / n_rows)

    return meta.new(rt.Cloth, {
        _is_realized = false,
        _width = width,
        _height = height,
        _node_distance_x = width / n_columns,
        _node_distance_y = height / n_rows,

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

        _grid_i_to_node_i = {{}}
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

    local row_i = 1
    local col_i = 1
    for i = 1, self._n_nodes do
        table.insert(self._positions, {current_x, current_y})
        table.insert(self._old_positions, {current_x, current_y})

        self._grid_i_to_node_i[col_i][row_i] = i
        table.insert(self._masses, (row_i + 1) / self._n_rows * 2)
        current_y = current_y + self._node_distance_y

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

    self._is_realized = true
end

function rt.Cloth:draw()
    if self._is_realized ~= true then return end
    local pairs = self._pairs
    local positions = self._positions
    local colors = self._colors

    love.graphics.setLineWidth(3)
    love.graphics.setPointSize(3)

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
end

function rt.Cloth:update(delta, n_iterations)
    local friction = 1
    local gravity_x = self._gravity_x
    local gravity_y = self._gravity_y
    local delta_squared = delta * delta

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

    local sqrt = math.sqrt
    local node_distance = self._node_distance_x
    local n = self._n_pairs

    -- TODO
    local x, y = love.mouse.getPosition()
    -- TODO

    -- apply constraints
    for _ = 1, n_iterations do

        self._positions[self._grid_i_to_node_i[1][1]] = {x - 0.4 * self._width, y}
        self._positions[self._grid_i_to_node_i[self._n_nodes_per_row][1]] = {x + 0.4 * self._width, y}

        for i = 1, n do
            local pair = self._pairs[i]

            local a_i, b_i = pair[1], pair[2]
            local node_1_i, node_2_i
            if a_i < b_i then
                node_1_i = a_i
                node_2_i = b_i
            else
                node_1_i = b_i
                node_2_i = a_i
            end

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
end

function rt.Cloth:set_anchor(i, x, y)

end