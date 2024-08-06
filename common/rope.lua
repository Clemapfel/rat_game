--- @class Rope
rt.Rope = meta.new_type("Rope", function(length, n_nodes, anchor_x, anchor_y)
    return meta.new(rt.Rope, {
        _is_realized = false,
        _n_nodes = n_nodes + 1,
        _node_distance = length / n_nodes,

        _friction = 0.02,    -- [0, 1], 1 maximum friction, 0 no friction
        _positions = {},     -- Table<Number> (size 2 * n)
        _old_positions = {}, -- Table<Number> (size 2 * n)
        _masses = {},        -- Table<Number> (size n)

        _gravity_x = 0,
        _gravity_y = 0,

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

--[[
 local atan2, sin, cos, abs = math.atan, math.sin, math.cos, math.abs
    local previous_angle = self._anchor_angle
    local max_angle = (90 / 360) * (2 * math.pi)
    for i = 1, n, 2 do
        local node_1_xi, node_1_yi, node_2_xi, node_2_yi = i, i+1, i+2, i+3
        local node_1_x, node_1_y = positions[node_1_xi], positions[node_1_yi]
        local node_2_x, node_2_y = positions[node_2_xi], positions[node_2_yi]

        local angle = atan2(node_2_y - node_1_y, node_2_x - node_1_x)
        local difference = 0 --(angle - previous_angle) / max_angle / 2

        local center_x, center_y = (node_1_x + node_2_x) / 2, (node_1_y + node_2_y) / 2

        node_1_x = node_1_x - center_x
        node_1_y = node_1_y - center_y
        node_1_x = node_1_x * cos(difference) - node_1_y * sin(difference)
        node_1_y = node_1_x * sin(difference) + node_1_y * cos(difference)
        node_1_x = node_1_x + center_x
        node_1_y = node_1_y + center_y

        difference = 0 --difference - (max_angle / 2)
        node_2_x = node_2_x - center_x
        node_2_y = node_2_y - center_y
        node_2_x = node_2_x * cos(difference) - node_2_y * sin(difference)
        node_2_y = node_2_x * sin(difference) + node_2_y * cos(difference)
        node_2_x = node_2_x + center_x
        node_2_y = node_2_y + center_y

        positions[node_1_xi] = node_1_x
        positions[node_1_yi] = node_1_y
        positions[node_2_xi] = node_2_x
        positions[node_2_yi] = node_2_y
    end
]]--