rt.settings.menu.object_get_scene = {
    n_shakes_per_second = 0.5,
    reveal_duration = 0.5
}

--- @class mn.ObjectGetScene
mn.ObjectGetScene = meta.new_type("ObjectGetScene", rt.Scene, function(state)
    return meta.new(mn.ObjectGetScene, {
        _state = state,
        _objects = {
            bt.MoveConfig("DEBUG_MOVE"),
            bt.ConsumableConfig("DEBUG_CONSUMABLE")
        },

        _sprites = {}
    })
end, {
    _reveal_shader = rt.Shader("menu/object_get_scene_reveal.glsl")
})

--- @brief
function mn.ObjectGetScene:realize()
    if self:already_realized() then return end

    local black = rt.Palette.BLACK
    self._reveal_shader:send("black", {black.r, black.g, black.b})

    local shake_duration = 1 / rt.settings.menu.object_get_scene.n_shakes_per_second
    local color_duration = rt.settings.menu.object_get_scene.reveal_duration
    local angle_magnitude = 0.05 * math.pi
    for object in values(self._objects) do
        local sprite = rt.Sprite(object:get_sprite_id())
        sprite:realize()
        local sprite_w, sprite_h = sprite:measure()
        sprite_w = sprite_w * 2
        sprite_h = sprite_h * 2
        sprite:fit_into(0, 0, sprite_w, sprite_h)
        table.insert(self._sprites, {
            sprite = sprite,
            sprite_w = sprite_w,
            sprite_h = sprite_h,
            x = 0.5 * love.graphics.getWidth() - 0.5 * sprite_w,
            y = 0.5 * love.graphics.getHeight() - 0.5 * sprite_h,
            shake_animation = rt.TimedAnimation(shake_duration, -angle_magnitude, angle_magnitude, rt.InterpolationFunctions.SINE_WAVE),
            shake_animation_start = true,
            center_x = 0.5 * sprite_w,
            center_y = 1 * sprite_h,
            angle = 0,
            color = 0,
            color_animation = rt.TimedAnimation(color_duration, 0, 1, rt.InterpolationFunctions.LINEAR),
            color_animation_started = true,

            slot_mesh_top = nil, -- rt.VertexRectangle
            slot_mesh_bottom = nil, -- rt.VertexRectangle
            slots_visible = true
        })
    end

    local fireworks = {}
    self._fireworks = fireworks

    local scene = self
    fireworks.realize = function(self)
        self.render_shader = rt.Shader("menu/object_get_fireworks_render.glsl")
        self.step_shader = rt.ComputeShader("menu/object_get_fireworks_step.glsl")

        self.n_groups = 3
        self.n_particles_per_group = 800
        self.particle_radius = 5
        local perturbation = 0.024
        self.dim_velocity = 0.9

        local n_particles = self.n_particles_per_group * self.n_groups

        local particle_buffer_format = self.step_shader:get_buffer_format("particle_buffer_a")
        self.particle_buffer_a = rt.GraphicsBuffer(particle_buffer_format, n_particles)
        self.particle_buffer_b = rt.GraphicsBuffer(particle_buffer_format, n_particles)

        local group_buffer_format = self.step_shader:get_buffer_format("group_buffer")
        self.group_buffer = rt.GraphicsBuffer(group_buffer_format, self.n_groups)

        local fade_out_buffer_format = self.step_shader:get_buffer_format("fade_out_buffer")
        self.fade_out_buffer = rt.GraphicsBuffer(fade_out_buffer_format, 1)

        local w, h = scene._bounds.width, scene._bounds.height
        do
            local group_data = {}
            local particle_data = {}
            local group_to_center = {
                [1] = {0.25 * w, 0.2 * h, 0},
                [2] = {0.5 * w, 0.2 * h, 0},
                [3] = {0.75 * w, 0.2 * h, 0}
            }

            local group_data = {}
            local particle_data = {}
            local initial_velocity = 10

            for group_i = 1, self.n_groups do
                local cx, cy, cz = table.unpack(group_to_center[group_i])
                table.insert(group_data, {
                    cx, cy, cz, 1
                })

                for particle_i = 1, self.n_particles_per_group do

                    local index = particle_i - 1 + 0.5
                    local phi = math.acos(1 - 2 * index / self.n_particles_per_group)
                    local theta = math.pi * (1 + math.sqrt(5)) * index

                    phi = phi + rt.random.number(-perturbation * math.pi, perturbation * math.pi)
                    theta = theta + rt.random.number(-perturbation * math.pi, perturbation * math.pi)

                    local vx = math.cos(theta) * math.sin(phi)
                    local vy = math.sin(theta) * math.sin(phi)
                    local vz = math.cos(phi)

                    table.insert(particle_data, {
                        cx, cy, cz,
                        vx, vy, vz,
                        initial_velocity * vx, initial_velocity * vy, initial_velocity * vz,
                        rt.random.number(0, 1), -- hue
                        1, -- value
                        1, -- mass
                        group_i - 1
                    })
                end
            end

            self.particle_buffer_a:replace_data(particle_data)
            self.particle_buffer_b:replace_data(particle_data)
            self.group_buffer:replace_data(group_data)
            self.group_data = group_data
        end

        self.update_group_data = function(self, mode)
            for i = 1, self.n_groups do
                self.group_data[i][4] = mode
            end
            self.group_buffer:replace_data(self.group_data)
        end

        self.particle_mesh = rt.VertexCircle(0, 0, self.particle_radius)
        local particle_texture_w = 1000
        self.particle_mesh_texture = rt.RenderTexture(particle_texture_w, particle_texture_w, rt.TextureFormat.R32F)
        self.particle_texture_shader = rt.Shader("menu/object_get_fireworks_particle_texture.glsl")

        do
            love.graphics.push()
            love.graphics.origin()
            self.particle_mesh_texture:bind()
            self.particle_texture_shader:bind()
            love.graphics.rectangle("fill", 0, 0, particle_texture_w, particle_texture_w)
            self.particle_texture_shader:unbind()
            self.particle_mesh_texture:unbind()
            love.graphics.pop()
            self.particle_mesh:set_texture(fireworks.particle_mesh_texture)
        end

        for name_value in range(
            {"particle_buffer_a", self.particle_buffer_a},
            {"particle_buffer_a", self.particle_buffer_a},
            {"particle_buffer_b", self.particle_buffer_b},
            {"group_buffer", self.group_buffer},
            {"fade_out_buffer", self.fade_out_buffer},
            {"n_groups", self.n_groups},
            {"n_particles_per_group",self.n_particles_per_group}
        ) do
           self.step_shader:send(table.unpack(name_value))
        end

        self.texture = rt.RenderTexture(w, h, rt.TextureFormat.RGBA32F)

        local fireworks_dispatch_size = math.ceil(math.sqrt(n_particles) / 32)
        self.a_or_b = true
        self.elapsed = 0
        local so_far = 0
        local buffer_ready = self.fade_out_buffer:readback_data_async()
        local fade_out_color = 1

        self.update = function(self, delta)
            self.elapsed = self.elapsed + delta

            so_far = so_far + delta
            local step = 1 / 120
            while so_far > step do
                if self.a_or_b then
                    self.step_shader:send("particle_buffer_a", self.particle_buffer_a)
                    self.step_shader:send("particle_buffer_b", self.particle_buffer_b)
                    self.render_shader:send("particle_buffer", self.particle_buffer_b)
                else
                    self.step_shader:send("particle_buffer_a", self.particle_buffer_b)
                    self.step_shader:send("particle_buffer_b", self.particle_buffer_a)
                    self.render_shader:send("particle_buffer", self.particle_buffer_a)
                end
                self.a_or_b = not self.a_or_b

                self.step_shader:send("elapsed", self.elapsed)
                self.step_shader:send("delta", step)
                self.step_shader:dispatch(fireworks_dispatch_size, fireworks_dispatch_size)

                self.texture:bind()
                love.graphics.setBlendMode("subtract")
                love.graphics.setColor(step * self.dim_velocity, step * self.dim_velocity, step * self.dim_velocity, 1)
                love.graphics.rectangle("fill", 0, 0, self.texture:get_size())
                love.graphics.setBlendMode("alpha")

                self.render_shader:bind()
                self.render_shader:send("use_value", true)

                if buffer_ready:isComplete() then
                    fade_out_color = buffer_ready:getBufferData():getFloat(0)
                    buffer_ready = self.fade_out_buffer:readback_data_async()
                end

                love.graphics.setColor(fade_out_color, fade_out_color, fade_out_color, 1)
                self.particle_mesh:draw_instanced(self.n_particles_per_group * self.n_groups)
                self.render_shader:unbind()
                self.texture:unbind()

                so_far = so_far - step
            end
        end

        self.draw = function(self)
            self.texture:draw()
        end
    end
    fireworks:realize()

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(self, which)
        if which == rt.InputButton.A then
            fireworks:update_group_data(1)
        elseif which == rt.InputButton.X then
            fireworks:realize()
        end
    end)
end

function mn.ObjectGetScene:size_allocate(x, y, width, height)
    local total_w, max_h, max_w = 0, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local n_sprites = 0
    for entry in values(self._sprites) do
        total_w = total_w + entry.sprite_w
        max_h = math.max(max_h, entry.sprite_h)
        max_w = math.max(max_w, entry.sprite_w)
        n_sprites = n_sprites + 1
    end

    local slot_h = 2 * max_h
    local slot_w = max_w

    local black = rt.Palette.BLACK
    local non_black = rt.RGBA(black.r, black.g, black.b, 0)

    local margin = math.max((0.5 * width - total_w) / (n_sprites - 1), rt.settings.margin_unit)
    margin = 0
    local current_x = x + 0.5 * width - 0.5 * total_w
    local current_y = y + 0.5 * height
    for entry in values(self._sprites) do
        entry.x = current_x
        entry.y = current_y - 0.5 * entry.sprite_h

        entry.slot_mesh_bottom = rt.VertexRectangle(entry.x, entry.y + 0.5 * entry.sprite_w, slot_w, slot_h)
        entry.slot_mesh_top = rt.VertexRectangle(entry.x, entry.y + 0.5 * entry.sprite_w - slot_h, slot_w, slot_h)

        entry.slot_mesh_bottom:set_vertex_color(1, black)
        entry.slot_mesh_bottom:set_vertex_color(2, black)
        entry.slot_mesh_bottom:set_vertex_color(3, non_black)
        entry.slot_mesh_bottom:set_vertex_color(4, non_black)

        entry.slot_mesh_top:set_vertex_color(1, non_black)
        entry.slot_mesh_top:set_vertex_color(2, non_black)
        entry.slot_mesh_top:set_vertex_color(3, black)
        entry.slot_mesh_top:set_vertex_color(4, black)

        entry.slots_visible = true
        current_x = current_x + entry.sprite_w + margin
    end
end

--- @brief
function mn.ObjectGetScene:update(delta)
    for entry in values(self._sprites) do
        if entry.shake_animation_start then
            entry.shake_animation:update(delta)
        end
        entry.angle = entry.shake_animation:get_value()

        if entry.color_animation_started then
            entry.color_animation:update(delta)
        end
        entry.color = entry.color_animation:get_value()
    end

    self._fireworks:update(delta)
end

--- @brief
function mn.ObjectGetScene:draw()
    --[[
    for entry in values(self._sprites) do
        love.graphics.push()
        love.graphics.origin()

        if entry.slots_visible then
            entry.slot_mesh_top:draw()
            entry.slot_mesh_bottom:draw()
        end

        self._reveal_shader:bind()
        love.graphics.translate(entry.x, entry.y)
        love.graphics.translate(entry.center_x, entry.center_y)
        love.graphics.rotate(entry.angle)
        love.graphics.translate(-entry.center_x, -entry.center_y)
        self._reveal_shader:send("color", entry.color)
        entry.sprite:draw()
        self._reveal_shader:unbind()

        love.graphics.pop()
    end
    ]]--

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    self._fireworks:draw()
end

--- @override
function mn.ObjectGetScene:make_active()
    -- TODO
end

--- @override
function mn.ObjectGetScene:make_inactive()

end