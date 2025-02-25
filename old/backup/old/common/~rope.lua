-- src: https://github.com/Toqozz/blog-code/blob/master/rope/Assets/Rope.cs
-- src: https://www.owlree.blog/posts/simulating-a-rope.html

--- @class VerletNode
function VerletNode(position_x, position_y, mass)
    return {
        mass = mass,
        position_x = position_x,
        position_y = position_y,
        old_position_x = position_x,
        old_position_y = position_y
    }
end

--- @class Rope
rt.Rope = meta.new_type("Rope", function(x, y, n_vertices, vertex_distance)
    return meta.new(rt.Rope, {
        is_realized = false,
        initial_pos_x = x,
        initial_pos_y = y,

        total_nodes = which(n_vertices, 40),
        node_distance = which(vertex_distance, 0.1),

        step_time = 0.01,
        max_step = 0.1,

        gravity_x = 0,
        gravity_y = 30,

        anchor_x = 0,
        anchor_y = 0,

        nodes = {}, -- Table<VerletNode>
        n_nodes = 0,

        draw_buffer = {},
        node_colors = {}
    })
end)

function rt.Rope:realize()
    local position_x, position_y = self.initial_pos_x, self.initial_pos_y
    local initial_mass = 50
    local mass = initial_mass
    for i = 1, self.total_nodes do
        local node = VerletNode(position_x, position_y, mass)
        self.nodes[i] = node
        position_y = position_y + self.node_distance
        mass = mass + 1
    end
    self.n_nodes = self.total_nodes
    self.is_realized = true

    -- pre-calculate colors
    for i = 1, self.n_nodes do
        local node = self.nodes[i]
        local color = rt.hsva_to_rgba(rt.HSVA((node.mass - initial_mass) / (mass - initial_mass), 1, 1, 1))
        self.node_colors[i] = {color.r, color.g, color.b, color.a}
    end
end

function rt.Rope:draw()
    if self.is_realized == false then return end

    love.graphics.setLineWidth(3)
    for i = 1, self.n_nodes - 1 do
        local node_1, node_2 = self.nodes[i], self.nodes[i + 1]
        local color = self.node_colors[i]
        love.graphics.setColor(table.unpack(color))
        love.graphics.line(node_1.position_x, node_1.position_y, node_2.position_x, node_2.position_y)
    end
end

function rt.Rope:update(delta, n_iterations)
    n_iterations = which(n_iterations, 80)

    self:verlet_step(delta)

    for i = 1, n_iterations do
        local mouse_x, mouse_y = love.mouse.getPosition()
        self.nodes[1].position_x = mouse_x
        self.nodes[1].position_y = mouse_y

        self:apply_constraints()
    end
end

function rt.Rope:verlet_step(delta)
    for i = 1, self.n_nodes do
        local node = self.nodes[i]
        local temp_x, temp_y = node.position_x, node.position_y

        node.position_x = node.position_x + (node.position_x - node.old_position_x) + node.mass * self.gravity_x * (delta * delta)
        node.position_y = node.position_y + (node.position_y - node.old_position_y) + node.mass * self.gravity_y * (delta * delta)

        node.old_position_x = temp_x
        node.old_position_y = temp_y
    end
end

function rt.Rope:apply_constraints()
    for i = 1, self.n_nodes - 1 do
        local node_1, node_2 = self.nodes[i], self.nodes[i + 1]

        local diff_x = node_1.position_x - node_2.position_x
        local diff_y = node_1.position_y - node_2.position_y

        local dist = rt.distance(node_1.position_x, node_1.position_y, node_2.position_x, node_2.position_y)
        local difference = 0

        if dist > 0 then
            difference = (self.node_distance - dist) / dist
        end

        local translate_x = diff_x * 0.5 * difference
        local translate_y = diff_y * 0.5 * difference

        node_1.position_x = node_1.position_x + translate_x
        node_1.position_y = node_1.position_y + translate_y

        node_2.position_x = node_2.position_x - translate_x
        node_2.position_y = node_2.position_y - translate_y
    end
end

function rt.Rope:relax()
    for node in values(self.nodes) do
        node.old_position_x = node.position_x
        node.old_position_y = node.position_y
    end
end
