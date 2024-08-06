require "common.common"

local args = {...}
main_to_worker = args[1]
worker_to_main = args[2]

function _new_rope(x, y, length, n_nodes, gravity_x, gravity_y)
    local node_distance = length / n_nodes
    local out = {
        positions = {},
        old_positions = {},
        masses = {},
        colors = {},
        n_nodes = n_nodes,
        node_distance = node_distance,
        anchor_x = x,
        anchor_y = y,
        gravity_x = gravity_x,
        gravity_y = gravity_y
    }

    local mass_distribution = function(x)
        assert(x >= 0 and x <= 1)
        return 1 - x
    end

    local max_mass = 1
    for i = 1, n_nodes do
        table.insert(out.positions, x)
        table.insert(out.positions, y)
        table.insert(out.old_positions, x)
        table.insert(out.old_positions, y)
        table.insert(out.masses, mass_distribution((n_nodes - i) / n_nodes) * max_mass)

        table.insert(out.colors, {rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(i / n_nodes, 1, 1, 1)))})
        y = y + node_distance
    end

    return out
end

function _draw_rope(rope)
    love.graphics.line(rope.positions)
    --[[
    love.graphics.setLineWidth(1)
    local n_nodes = rope.n_nodes
    local n = 2 * (n_nodes - 1)
    for i = 1, n, 2 do
        local node_1_x, node_1_y = rope.positions[i], rope.positions[i + 1]
        local node_2_x, node_2_y = rope.positions[i + 2], rope.positions[i + 3]

        local color = rope.colors[(i + 1) / 2]
        love.graphics.setColor(table.unpack(color))
        love.graphics.line(node_1_x, node_1_y, node_2_x, node_2_y)
    end
    ]]
end

function _verlet_step(delta, n_nodes, gravity_x, gravity_y, friction, positions, old_positions, masses)
    local delta_squared = delta * delta
    local n = 2 * n_nodes
    friction = clamp(friction, 0, 1)
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

function _jakobsen_constraint_step(n_nodes, node_distance, positions)
    local sqrt = math.sqrt
    local n = 2 * (n_nodes - 1)

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

while THREAD_ID ~= 0 do
    local message = main_to_worker:demand()
    local id = message

    local n_iterations = message.n_iterations   -- Unsigned
    local delta = message.delta                 -- seconds
    local n_nodes = message.n_nodes             -- Unsigned
    local node_distance = message.node_distance -- Number
    local gravity_x = message.gravity_x         -- Number
    local gravity_y = message.gravity_y         -- Number
    local anchor_x = message.anchor_x           -- Number
    local anchor_y = message.anchor_y           -- Number
    local friction = message.friction           -- Number [0, 1]
    local positions = message.positions         -- Table<Number>, 2 * n
    local old_positions = message.old_positions -- Table<Number>, 2 * n
    local masses = message.masses               -- Table<Number>, n

    _verlet_step(
        delta,
        n_nodes,
        gravity_x,
        gravity_y,
        friction,
        positions,
        old_positions,
        masses
    )

    for i = 1, n_iterations do
        positions[1] = anchor_x
        positions[2] = anchor_y
        _jakobsen_constraint_step(
            n_nodes,
            node_distance,
            positions
        )
    end

    worker_to_main:push({
        id = message.id,
        positions = positions,
        old_positions = old_positions
    })
end