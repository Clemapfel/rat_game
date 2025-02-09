require "include"

local self = _G

self._max_split_depth = 20 -- number of times a branch can become 2 branches
self._step = 1 / 120
self._radius = 3

self.realize = function(self)
    self._step_shader = rt.ComputeShader("vessels_step.glsl", {
        MODE = 0
    })

    self._mark_active_shader = rt.ComputeShader("vessels_step.glsl", {
        MODE = 1
    })

    self._draw_shader = rt.Shader("vessels_draw.glsl")

    local buffer_format = self._step_shader:get_buffer_format("BranchBuffer")
    local branch_data = {}

    -- seed
    local width, height = love.graphics.getDimensions()
    local push_seed_branch = function(px, py, vx, vy)
        table.insert(branch_data, {
            [1] = 1,   -- is_active
            [2] = 0,  -- mark_active
            [3] = px,  -- position
            [4] = py,
            [5] = vx,   -- velocity
            [6] = vy,
            [7] = 0,   -- angular_velocity
            [8] = 1,   -- mass
            [9] = 0,   -- distance_since_last_split
s            [11] = 0,  -- has_split
            [12] = 0,  -- split_depth
        })
    end

    push_seed_branch(0.5 * width, 0.5 * height, 0, -1)
    --push_seed_branch(0.5 * width, 0.5 * height, 0, 1)
    --push_seed_branch(0.5 * width, 0.5 * height, -1, 0)
    --push_seed_branch(0.5 * width, 0.5 * height,  1, 0)

    -- recursive pre-split branches, because gpu needs to know the next index to write to
    local push_branch = function(depth)
        table.insert(branch_data, {
            0, 0,
            0, 0,
            0, 0, 0, 1,
            0,
            -1,
            0, depth
        })
    end

    local max_branch_i = 1
    local current_n_branches = sizeof(branch_data)
    local start_i = 1
    for _ = 1, self._max_split_depth do
        local end_n = current_n_branches
        for i = start_i, end_n do
            local data = branch_data[i]
            if data[10] == -1 or data[11] == -1 then -- not yet split
                local current_depth = data[12]
                push_branch(current_depth + 1)
                data[10] = max_branch_i + 1
                max_branch_i = max_branch_i + 1
                current_n_branches = current_n_branches + 1
            end
        end
    end

    --dbg(branch_data)

    -- last pushed branches will keep -1, -1, but split depth signals to stop there
    local branch_buffer = rt.GraphicsBuffer(buffer_format, current_n_branches)
    branch_buffer:replace_data(branch_data)


    self._branch_buffer = branch_buffer
    self._n_branches = current_n_branches

    for name_value in range(
        {"BranchBuffer", self._branch_buffer},
        {"n_branches", self._n_branches},
        {"max_split_depth", self._max_split_depth},
        {"delta", self._step},
        {"noise_offset", love.math.random(-1000, 1000)}
    ) do
        local name, value = table.unpack(name_value)
        if self._step_shader:has_uniform(name) then
            self._step_shader:send(name, value)
        end
    end

    for name_value in range(
        {"BranchBuffer", self._branch_buffer},
        {"n_branches", self._n_branches}
    ) do
        local name, value = table.unpack(name_value)
        if self._mark_active_shader:has_uniform(name) then
            self._mark_active_shader:send(name, value)
        end
    end

    for name_value in range(
        {"BranchBuffer", self._branch_buffer},
        {"max_split_depth", self._max_split_depth},
        {"radius", self._radius}
    ) do
        local name, value = table.unpack(name_value)
        self._draw_shader:send(name, value)
    end

    self._branch_mesh = rt.VertexCircle(0, 0, 1, 1)
    self._dispatch_x = math.ceil(math.sqrt(current_n_branches) / 32)
    self._dispatch_y = self._dispatch_size_x

    -- sdf

    self._sdf_init_shader = rt.ComputeShader("vessels_sdf.glsl", {MODE = 0})
    self._sdf_step_shader = rt.ComputeShader("vessels_sdf.glsl", {MODE = 1})
    self._sdf_compute_gradient_shader = rt.ComputeShader("vessels_sdf.glsl", {MODE = 2})

    self:size_allocate(0, 0, love.graphics.getDimensions())
end

self.size_allocate = function(self, x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
    if true then --self._render_texture == nil or self._render_texture:getWidth() ~= width or self._render_texture:getHeight() ~= height then
        self._render_texture = love.graphics.newCanvas(width, height, {
            msaa = 4,
            format = rt.TextureFormat.RGBA8,
            computewrite = true
        })

        self._sdf_init_shader:send("hitbox_texture", self._render_texture)

        local sdf_texture_config = {
            format = rt.TextureFormat.RGBA32F,
            computewrite = true
        } -- xy: nearest true wall pixel, z: distance

        self._sdf_texture_a = love.graphics.newCanvas(self._area_w, self._area_h, sdf_texture_config)
        self._sdf_texture_b = love.graphics.newCanvas(self._area_w, self._area_h, sdf_texture_config)

        self._sdf_dispatch_x, self._sdf_dispatch_y = math.ceil(width) / 32 + 1, math.ceil(height) / 32 + 1

        for name_value in range(
            {"input_texture", self._sdf_texture_a},
            {"output_texture", self._sdf_texture_a}
        ) do
            local name, value = table.unpack(name_value)
            self._sdf_init_shader:send(name, value)
            self._sdf_step_shader:send(name, value)
            self._sdf_compute_gradient_shader:send(name, value)
        end
        self._sdf_init_shader:send("hitbox_texture", self._render_texture)
    end
end

local elapsed = 0
self.update = function(self, delta)
    elapsed = elapsed + delta
    while elapsed > self._step do
        -- draw
        love.graphics.setCanvas(self._render_texture)
        self._draw_shader:bind()
        love.graphics.setColor(1, 1, 1, 1)
        self._branch_mesh:draw_instanced(self._n_branches)
        self._draw_shader:unbind()
        love.graphics.setCanvas(nil)

        -- jump flood fill
        self._sdf_init_shader:dispatch(self._sdf_dispatch_x, self._sdf_dispatch_y)

        local jump = 0.5 * math.min(self._bounds.width, self._bounds.height)
        local jump_a_or_b = true
        while jump >= 1 do
            if jump_a_or_b then
                self._sdf_step_shader:send("input_texture", self._sdf_texture_a)
                self._sdf_step_shader:send("output_texture", self._sdf_texture_b)
            else
                self._sdf_step_shader:send("input_texture", self._sdf_texture_b)
                self._sdf_step_shader:send("output_texture", self._sdf_texture_a)
            end

            self._sdf_step_shader:send("jump_distance", math.ceil(jump))
            self._sdf_step_shader:dispatch(self._sdf_dispatch_x, self._sdf_dispatch_y)

            jump_a_or_b = not jump_a_or_b
            jump = jump / 2
        end

        if jump_a_or_b then
            self._sdf_compute_gradient_shader:send("input_texture", self._sdf_texture_a)
            self._sdf_compute_gradient_shader:send("output_texture", self._sdf_texture_b)
            self._step_shader:send("sdf_texture", self._sdf_texture_b)
            self._sdf_texture = self._sdf_texture_b -- TODO
        else
            self._sdf_compute_gradient_shader:send("input_texture", self._sdf_texture_b)
            self._sdf_compute_gradient_shader:send("output_texture", self._sdf_texture_a)
            self._step_shader:send("sdf_texture", self._sdf_texture_a)
            self._sdf_texture = self._sdf_texture_a -- TODO
        end

        self._sdf_compute_gradient_shader:dispatch(self._sdf_dispatch_x, self._sdf_dispatch_y)

        -- step
        self._step_shader:dispatch(self._dispatch_x, self._dispatch_y)
        self._mark_active_shader:dispatch(self._dispatch_x, self._dispatch_y)

        elapsed = elapsed - self._step
    end
end

self.draw = function(self)
    if self._sdf_texture ~= nil then
        --love.graphics.draw(self._sdf_texture)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._render_texture, 0, 0)
end

love.load = function()
    local before = love.timer.getTime()
    self:realize()
    dbg((love.timer.getTime() - before) / (1 / 60))
end

love.update = function(delta)
    if love.keyboard.isDown("space") then
        self:update(delta)
    end
end

love.draw = function()
    self:draw()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self._n_branches .. " | " .. love.timer.getFPS(), 5, 5, POSITIVE_INFINITY)
end

love.keypressed = function(which)
    if which == "x" then
        self:realize()
        love.graphics.setCanvas(self._render_texture)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setCanvas(nil)
    elseif which == "b" then
        self._branch_buffer:readback_now()
        for i = 1, self._n_branches do
            dbg("[" .. i .. "] = ", self._branch_buffer:at(i))
        end
    end
end

