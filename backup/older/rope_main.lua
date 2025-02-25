require "include"

rt.ClothSimulation = meta.new_type("ClothSimulation", function()
    return meta.new(rt.ClothSimulation, {

    })
end)


function rt.ClothSimulation:realize()
    self._verlet_step_shader = rt.ComputeShader("rope_verlet_step.glsl")
    self._apply_constraints_shader = rt.ComputeShader("rope_apply_constraints.glsl")
    self._apply_anchors_shader = rt.ComputeShader("rope_apply_anchors.glsl")

    self._n_nodes = 0
    self._n_node_pairs = 0
    self._n_anchors = 1
    self._n_constraint_iterations = 256
    self._friction = 0
    self._gravity = 1

    local buffer_usage = {
        shaderstorage = true,
        usage = "static"
    }

    self._initialize_node_buffers = function(self)
        local fraction = 0.75
        local width, height = love.graphics.getDimensions()
        local x, y, w, h = (1 - fraction) * width / 2, (1 - fraction) * height / 2, fraction * width, fraction * height
        local step = 10
        local node_data = {}
        local node_pair_data = {}

        local n_nodes = 0
        local node_i = 1
        for i = 1, h / step do
            for j = 1, w / step do
                table.insert(node_data, {
                    x + (j - 1) * step, y + (i - 1) * step,
                    x + (j - 1) * step, y + (i - 1) * step,
                    1
                })
                node_i = node_i + 1

                table.insert(node_pair_data, {
                    node_i - 1, node_i, step
                })
            end
        end

        self._n_nodes = sizeof(node_data)
        self._n_node_pairs = sizeof(node_pair_data)


        --[[
        local n_rows, n_columns = math.ceil(w / step), math.ceil(h / step)
        self._n_nodes = n_rows * n_columns
        self._n_rows = n_rows
        self._n_columns = n_columns

        local node_matrix = {}


        local current_row = {}
        local node_i = 1

        for row_i = 1, n_rows do
            local row = {}
            for column_i = 1, n_columns do
                local current_x, current_y = x + (row_i - 1) * step, y + (column_i - 1) * step
                table.insert(node_data, {
                    current_x, current_y,   -- position
                    current_x, current_y,   -- old_position
                    1       -- mass
                })
                table.insert(row, node_i)
                node_i = node_i + 1
            end
            table.insert(node_matrix, row)
        end

        local n_pairs = 0
        for row_i = 1, n_rows do
            for column_i = 1, n_columns do
                local current = node_matrix[row_i][column_i]
                local hnext = node_matrix[row_i][column_i + 1]
                if hnext ~= nil then
                    table.insert(node_pair_data, {
                        current - 1, hnext - 1, step
                    })
                    n_pairs = n_pairs + 1
                end

                if node_matrix[row_i + 1] ~= nil then
                    local vnext = node_matrix[row_i + 1][column_i]
                    if vnext ~= nil then
                        table.insert(node_pair_data, {
                            current - 1, vnext - 1, step
                        })
                        n_pairs = n_pairs + 1
                    end
                end
            end
        end
        self._n_node_pairs = n_pairs
        ]]--

        local node_buffer_format = self._apply_constraints_shader:get_buffer_format("node_buffer_a")
        self._node_buffer_a = love.graphics.newBuffer(node_buffer_format, self._n_nodes, buffer_usage)
        self._node_buffer_b = love.graphics.newBuffer(node_buffer_format, self._n_nodes, buffer_usage)
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
            {0, x, y },
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
    self._verlet_step_shader:send("friction", self._friction)
    self._verlet_step_shader:send("gravity_factor", self._gravity)

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
        shader:send("line_thickness", self._line_thickness)
    end

    self._draw_segments_shader:send("n_instances", self._n_node_pairs)
    self._draw_joints_shader:send("n_instances", self._n_nodes)
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
    local a_or_b = false
    local node_buffer
    for i = 1, self._n_constraint_iterations do
        if a_or_b then
            self._apply_constraints_shader:send("node_buffer_a", self._node_buffer_b)
            self._apply_constraints_shader:send("node_buffer_b", self._node_buffer_a)
            node_buffer = self._node_buffer_b
        else
            self._apply_constraints_shader:send("node_buffer_a", self._node_buffer_a)
            self._apply_constraints_shader:send("node_buffer_b", self._node_buffer_b)
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
    love.graphics.printf(sim._n_node_pairs .. " * " .. sim._n_constraint_iterations .. " | " .. love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
end

