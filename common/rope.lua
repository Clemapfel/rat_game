-- src: https://github.com/Toqozz/blog-code/blob/master/rope/Assets/Rope.cs
-- src: https://www.owlree.blog/posts/simulating-a-rope.html

--- @class Rope
rt.Rope = meta.new_type("Rope", function(n_nodes, node_distance)
    return meta.new(rt.Rope, {
        _is_realized = false,
        _n_nodes = n_nodes,
        _node_distance = node_distance,

        _positions = {},
        _old_positions = {},

        _gravity_x = 0,
        _gravity_y = 2000,

        _colors = {}
    })
end)

--- @brief
function rt.Rope:realize()
    local x, y = love.mouse.getPosition()
    for i = 1, self._n_nodes do
        table.insert(self._positions, x)
        table.insert(self._positions, y)
        table.insert(self._old_positions, x)
        table.insert(self._old_positions, y)

        y = y + self._node_distance
    end

    -- pre-calculate colors
    for i = 1, 2 * self._n_nodes, 2 do
        local node_x = self._positions[i]
        local node_y = self._positions[i+1]
        local color = rt.hsva_to_rgba(rt.HSVA((i / 2) / self._n_nodes, 1, 1, 1))
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
    self:_verlet_step(delta)
    for i = 1, n_iterations do
        local mouse_x, mouse_y = love.mouse.getPosition()
        self._positions[1] = mouse_x
        self._positions[2] = mouse_y
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

    for i = 1, n, 2 do
        local current_x, current_y = positions[i], positions[i+1]
        local old_x, old_y = old_positions[i], old_positions[i+1]

        local before_x, before_y = current_x, current_y

        positions[i] = current_x + (current_x - old_x) + gravity_x * delta_squared
        positions[i+1] = current_y + (current_y - old_y) + gravity_y* delta_squared

        old_positions[i] = before_x
        old_positions[i+1] = before_y
    end
end

--- @brief
function rt.Rope:_apply_jakobsen_constraints()
    local sqrt = math.sqrt
    local node_distance = self._node_distance
    local n = 2 * (self._n_nodes - 1)
    local positions = self._positions

    for i = 1, n, 2 do
        local node_1_xi, node_1_yi, node_2_xi, node_2_yi = i, i+1, i+2, i+3
        local node_1_x, node_1_y = positions[node_1_xi], positions[node_1_yi]
        local node_2_x, node_2_y = positions[node_2_xi], positions[node_2_yi]

        local diff_x = node_1_x - node_2_x
        local diff_y = node_1_y - node_2_y

        local distance
        do
            local a = node_2_x - node_1_x
            local b = node_2_y - node_1_y
            distance = sqrt(a * a + b * b)
        end

        local difference = (node_distance - distance) / distance

        local translate_x = diff_x * 0.5 * difference
        local translate_y = diff_y * 0.5 * difference

        positions[node_1_xi] = node_1_x + translate_x
        positions[node_1_yi] = node_1_y + translate_y
        positions[node_2_xi] = node_2_x - translate_x
        positions[node_2_yi] = node_2_y - translate_y
    end
end

--- @brief
function rt.Rope:relax()
    for i = 1, 2 * self.n_nodes, 2 do
        self._old_positions[i] = self._positions[i]
        self._old_positions[i+1] = self._positions[i+1]
    end
end
