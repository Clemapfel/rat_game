require "common.common"

local args = {...}
main_to_worker = args[1]
worker_to_main = args[2]

function _new_rope(x, y, length, n_nodes, gravity_x, gravity_y)
    local node_distance = length / n_nodes
    local out = {
        positions = {},
        old_positions = {},
        colors = {},
        n_nodes = n_nodes,
        node_distance = node_distance,
        anchor_x = x,
        anchor_y = y,
        gravity_x = gravity_x,
        gravity_y = gravity_y
    }

    for i = 1, n_nodes do
        table.insert(out.positions, x)
        table.insert(out.positions, y)
        table.insert(out.old_positions, x)
        table.insert(out.old_positions, y)

        table.insert(out.colors, {rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(i / n_nodes, 1, 1, 1)))})
        y = y + node_distance
    end

    return out
end

function _draw_rope(rope)
    love.graphics.setLineWidth(1)
    local n_nodes = rope.n_nodes
    local n = 2 * (n_nodes - 1)
    love.graphics.setColor(1, 1, 1, 1) --table.unpack(color))
    for i = 1, n, 2 do
        local node_1_x, node_1_y = rope.positions[i], rope.positions[i + 1]
        local node_2_x, node_2_y = rope.positions[i + 2], rope.positions[i + 3]

        local color = rope.colors[(i + 1) / 2]
        love.graphics.line(node_1_x, node_1_y, node_2_x, node_2_y)
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
    local mass = message.mass

    -- verlet step
    local delta_squared = delta * delta
    local n = 2 * n_nodes
    friction = clamp(friction, 0, 1)
    for i = 1, n, 2 do
        local current_x, current_y = positions[i], positions[i+1]
        local old_x, old_y = old_positions[i], old_positions[i+1]

        local before_x, before_y = current_x, current_y

        positions[i] = current_x + (current_x - old_x) * friction + mass * gravity_x * delta_squared
        positions[i+1] = current_y + (current_y - old_y) * friction + mass * gravity_y * delta_squared

        old_positions[i] = before_x
        old_positions[i+1] = before_y
    end

    -- jakobsen constraints
    local sqrt = math.sqrt
    local n = 2 * (n_nodes - 1)
    for i = 1, n_iterations do
        positions[1] = anchor_x
        positions[2] = anchor_y

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

    worker_to_main:push({
        id = message.id,
        positions = positions,
        old_positions = old_positions
    })
end

function _create_mesh(n_ropes, n_nodes, ropes)
    local vertices = {}
    local vertex_map = {}
    local vertex_format = {
        { name = "VertexPosition", format = "floatvec2" },
        { name = "VertexColor",    format = "floatvec4" }
    }

    local thickness = 3

    local n = 2 * (n_nodes - 1)
    local atan2 = math.atan2
    local offset = (1 / 8) * (2 * math.pi)
    local translate_by_angle = function(point_x, point_y, angle)
        return point_x + thickness * math.cos(angle), point_y + thickness * math.sin(angle)
    end

    local vertex_i = 1
    for rope_i = 1, n_ropes do
        local positions = ropes[rope_i].positions
        for node_i = 1, n, 2 do
            local node_1_x, node_1_y = positions[node_i], positions[node_i + 1]
            local node_2_x, node_2_y = positions[node_i + 2], positions[node_i + 3]

            local angle = atan2(node_2_y - node_1_y, node_2_x - node_1_x)
            local a1_x, a1_y = translate_by_angle(node_1_x, node_1_y, angle - offset)
            local a2_x, a2_y = translate_by_angle(node_1_x, node_1_y, angle + offset)
            local b1_x, b1_y = translate_by_angle(node_2_x, node_2_y, angle - offset)
            local b2_x, b2_y = translate_by_angle(node_2_x, node_2_y, angle + offset)

            local color = rt.hsva_to_rgba(rt.HSVA((node_i / 2) / (n_nodes), 1, 1, 1, 1))

            table.insert(vertices, { a1_x, a1_y, rt.color_unpack(color) })
            table.insert(vertices, { a2_x, a2_y, rt.color_unpack(color) })
            table.insert(vertices, { b1_x, b1_y, rt.color_unpack(color) })
            table.insert(vertices, { b2_x, b2_y, rt.color_unpack(color) })

            for i in range(
                vertex_i, vertex_i + 1, vertex_i + 3,
                vertex_i, vertex_i + 2, vertex_i + 3) do
                table.insert(vertex_map, i)
            end

            vertex_i = vertex_i + 4
        end
    end

    local mesh = love.graphics.newMesh(vertex_format, vertices, "triangles", "dynamic")
    mesh:setVertexMap(vertex_map)
    return mesh
end

function _update_mesh(mesh, n_ropes, n_nodes, ropes)
    local vertices = {}


    local thickness = 3

    local n = 2 * (n_nodes - 1)
    local atan2 = math.atan2
    local offset = (1 / 8) * (2 * math.pi)
    local translate_by_angle = function(point_x, point_y, angle)
        return point_x + thickness * math.cos(angle), point_y + thickness * math.sin(angle)
    end

    local vertex_i = 1
    for rope_i = 1, n_ropes do
        local positions = ropes[rope_i].positions
        for node_i = 1, n, 2 do
            local node_1_x, node_1_y = positions[node_i], positions[node_i + 1]
            local node_2_x, node_2_y = positions[node_i + 2], positions[node_i + 3]

            local angle = atan2(node_2_y - node_1_y, node_2_x - node_1_x)
            local a1_x, a1_y = translate_by_angle(node_1_x, node_1_y, angle - offset)
            local a2_x, a2_y = translate_by_angle(node_1_x, node_1_y, angle + offset)
            local b1_x, b1_y = translate_by_angle(node_2_x, node_2_y, angle - offset)
            local b2_x, b2_y = translate_by_angle(node_2_x, node_2_y, angle + offset)

            local color = rt.hsva_to_rgba(rt.HSVA((node_i / 2) / (n_nodes), 1, 1, 1, 1))

            vertices[vertex_i + 0] = { a1_x, a1_y, rt.color_unpack(color) }
            vertices[vertex_i + 1] = { a2_x, a2_y, rt.color_unpack(color) }
            vertices[vertex_i + 2] = { b1_x, b1_y, rt.color_unpack(color) }
            vertices[vertex_i + 3] = { b2_x, b2_y, rt.color_unpack(color) }

            vertex_i = vertex_i + 4
        end
    end

    mesh:setVertices(vertices)
end