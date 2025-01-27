require "include"

rt.ClothSimulation = meta.new_type("ClothSimulation", function()
    return meta.new(rt.ClothSimulation, {

    })
end)


function rt.ClothSimulation:realize()
    self._verlet_step_shader = rt.ComputeShader("rope_verlet_step.glsl")
    self._apply_constraints_shader = rt.ComputeShader("rope_apply_constraints.glsl")
    self._apply_anchors_shader = rt.ComputeShader("rope_apply_anchors.glsl")

    self._n_nodes = 1000
    self._n_node_pairs = 0
    self._n_anchors = 1
    self._n_constraint_iterations = 256

    local buffer_usage = {
        shaderstorage = true,
        usage = "static"
    }

    local node_buffer_format = self._apply_constraints_shader:get_buffer_format("node_buffer_a")
    self._node_buffer_a = love.graphics.newBuffer(node_buffer_format, self._n_nodes, buffer_usage)
    self._node_buffer_b = love.graphics.newBuffer(node_buffer_format, self._n_nodes, buffer_usage)

    self._initialize_node_buffers = function(self)
        local node_data = {}
        local node_pair_data = {}
        local x, y = 0.5 * love.graphics.getWidth(), 0.5 * love.graphics.getHeight()
        local y_step = love.graphics.getHeight() / self._n_nodes
        local x_step = 20
        local length = 0.5 * love.graphics.getHeight() / self._n_nodes
        for i = 1, self._n_nodes do
            table.insert(node_data, {
                x, y,   -- position
                x, y,   -- old_position
                1       -- mass
            })

            local vx, vy = rt.random.number(-1, 1), rt.random.number(-1, 1)
            vx, vy = rt.normalize(vx, vy)
            x = x + vx * y_step
            y = y + vy * y_step

            if i < self._n_nodes then
                table.insert(node_pair_data, {
                    i - 1, -- a_index
                    i,     -- b_index
                    length -- target_distance
                })
                self._n_node_pairs = self._n_node_pairs + 1
            end
        end

        self._node_buffer_a:setArrayData(node_data)
        self._node_buffer_b:setArrayData(node_data)

        local node_pair_buffer_format = self._apply_constraints_shader:get_buffer_format("node_pair_buffer")
        self._node_pair_buffer = love.graphics.newBuffer(node_pair_buffer_format, self._n_node_pairs, buffer_usage)
        self._node_pair_buffer:setArrayData(node_pair_data)
    end
    self:_initialize_node_buffers()

    local anchor_buffer_format = self._apply_anchors_shader:get_buffer_format("anchor_buffer")
    self._anchor_buffer = love.graphics.newBuffer(anchor_buffer_format, self._n_anchors, buffer_usage)

    self._update_anchors = function(self, x, y)
        local anchor_data = {
            {
                0, -- node_i
                x, y -- position
            }
        }
        self._anchor_buffer:setArrayData(anchor_data)
        self._apply_anchors_shader:send("anchor_buffer", self._anchor_buffer)
    end

    self._line_thickness = 5

    self._segment_mesh = rt.VertexRectangle(-0.5, -0.5, 1, 1)
    self._draw_segments_shader = rt.Shader("rope_draw.glsl", { MODE = 0 })

    self._joint_mesh = rt.VertexCircle(0, 0, 0.5 * self._line_thickness)
    self._draw_joints_shader = rt.Shader("rope_draw.glsl", { MODE = 1 })

    -- bind uniforms
    self._verlet_step_shader:send("node_buffer_a", self._node_buffer_a)
    self._verlet_step_shader:send("node_buffer_b", self._node_buffer_b)
    self._verlet_step_shader:send("n_nodes", self._n_nodes)

    self._apply_constraints_shader:send("node_buffer_a", self._node_buffer_a)
    self._apply_constraints_shader:send("node_buffer_b", self._node_buffer_b)
    self._apply_constraints_shader:send("node_pair_buffer", self._node_pair_buffer)
    self._apply_constraints_shader:send("n_node_pairs", self._n_node_pairs)

    self._apply_anchors_shader:send("node_buffer", self._node_buffer_a)
    self._apply_anchors_shader:send("anchor_buffer", self._anchor_buffer)
    self._apply_anchors_shader:send("n_anchors", self._n_anchors)

    for shader in range(
        self._draw_segments_shader,
        self._draw_joints_shader
    ) do
        shader:send("node_buffer", self._node_buffer_a)
        shader:send("node_pair_buffer", self._node_pair_buffer)
        shader:send("n_instances", self._n_node_pairs)
        shader:send("line_thickness", self._line_thickness)
    end
end

function rt.ClothSimulation:update(delta)
    -- verlet step
    local verlet_dispatch_size = math.ceil(math.sqrt(self._n_nodes) / 32)
    self._verlet_step_shader:send("delta", delta)
    self._verlet_step_shader:send("node_buffer_a", self._node_buffer_a)
    self._verlet_step_shader:send("node_buffer_b", self._node_buffer_b)
    self._verlet_step_shader:dispatch(verlet_dispatch_size, verlet_dispatch_size)

    -- jakobsen constraints
    local constraints_dispatch_size = math.ceil(math.sqrt(self._n_node_pairs) / 32)
    local a_or_b = true
    local node_buffer
    for i = 1, self._n_constraint_iterations do
        if a_or_b then
            self._apply_constraints_shader:send("node_buffer_a", self._node_buffer_a)
            self._apply_constraints_shader:send("node_buffer_b", self._node_buffer_b)
            node_buffer = self._node_buffer_b
        else
            self._apply_constraints_shader:send("node_buffer_b", self._node_buffer_a)
            self._apply_constraints_shader:send("node_buffer_a", self._node_buffer_b)
            node_buffer = self._node_buffer_a
        end
        a_or_b = not a_or_b

        self._apply_constraints_shader:dispatch(constraints_dispatch_size, constraints_dispatch_size)

        -- override anchor positions
        local anchor_dispatch_size = self._n_anchors
        self._apply_anchors_shader:dispatch(anchor_dispatch_size, 1)
    end
end

function rt.ClothSimulation:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    love.graphics.setColor(1, 1, 1, 1)

    self._draw_joints_shader:bind()
    self._joint_mesh:draw_instanced(self._n_nodes)
    self._draw_joints_shader:unbind()

    self._draw_segments_shader:bind()
    self._segment_mesh:draw_instanced(self._n_node_pairs)
    self._draw_segments_shader:unbind()
end

--

local sim = nil
love.load = function()
    love.window.setMode(800, 600, {
        vsync = -1,
        msaa = 8
    })

    sim = rt.ClothSimulation()
    sim:realize()
end

love.update = function(delta)
    sim:_update_anchors(love.mouse.getPosition())
    sim:update(delta)
end

love.keypressed = function(which)
    if which == "x" then
        sim:realize()
        sim:update(1 / 60)
    end
end

love.draw = function()
    sim:draw()

    -- show fps
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(sim._n_node_pairs * sim._n_constraint_iterations .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end

