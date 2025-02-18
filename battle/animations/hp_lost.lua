do
    local duration = 1.75
    rt.settings.battle.animations.hp_lost = {
        duration = duration,
        flinch_duration = 0.25,
        particle_velocity = 200, -- px per second
        particle_damping_speed = duration * 1.5, -- seconds until velocity is 0
        n_particles = 200
    }
end

--- @class bt.Animation.HP_LOST
bt.Animation.HP_LOST = meta.new_type("HP_LOST", rt.Animation, function(scene, entity, value, message)
    meta.assert_isa(scene,bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_number(value)
    if message ~= nil then meta.assert_string(message) end
    local settings = rt.settings.battle.animations.hp_lost
    return meta.new(bt.Animation.HP_LOST, {
        _scene = scene,
        _entity = entity,
        _target = nil,
        _value = value,

        _label = nil, -- rt.Label
        _label_path = nil, -- rt.Path
        _label_opacity_path = nil, -- rt.Path
        _label_path_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.EXPONENTIAL_ACCELERATION
        ),
        _label_scale_animation = rt.TimedAnimation(
            settings.duration / 2, 0, 1,
            rt.InterpolationFunctions.LINEAR
        ),
        _label_scale = 0,
        _label_x = 0,
        _label_y = 0,

        _target_path = nil, -- rt.Path
        _target_path_animation = rt.TimedAnimation(
            settings.flinch_duration, 0, 1,
            rt.InterpolationFunctions.DERIVATIVE_OF_GAUSSIAN_EASE_OUT
        ),
        _target_offset_x = 0,
        _target_offset_y = 0,

        _shader = nil, -- rt.Shader
        _shader_weight_animation = rt.TimedAnimation(
            settings.flinch_duration, 0, 1,
            rt.InterpolationFunctions.DERIVATIVE_OF_GAUSSIAN_EASE_OUT
        ),
        _shader_weight = 0,

        _particle_opacity = 0,
        _particle_opacity_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SHELF, 0.99, 6
        ),

        _particle_buffer = nil, -- rt.GraphicsBuffer
        _n_particles = settings.n_particles,
        _render_shader = nil, -- rt.Shader
        _step_shader = nil, -- rt.Shader

        _elapsed = 0,
        _duration = settings.duration,
        _radius_fraction = 1,

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

do
    local _shader = nil

    local _particle_step_shader = nil
    local _particle_render_shader = nil
    local _particle_mesh = nil

    --- @override
    function bt.Animation.HP_LOST:start()
        self._target = self._scene:get_sprite(self._entity)
        if _shader == nil then _shader = rt.Shader("battle/animations/hp_lost.glsl") end
        self._shader = _shader

        local target_x, target_y = self._target:get_position()
        local target_w, target_h = self._target:measure()

        self._label = rt.Label(
            "<b><o><color=ATTACK><mono>-" .. math.abs(self._value) .. "</mono></color></o></b>",
            rt.settings.font.default_large,
            rt.settings.font.default_mono_large
        )
        self._label:realize()
        local label_w, label_h = self._label:measure()
        self._label:fit_into(-0.5 * label_w, -0.5 * label_h)

        local center_x, center_y = target_x + 0.5 * target_w, target_y + 0.5 * target_h
        self._label_path = rt.Path(
            center_x, center_y,
            center_x, center_y,
            center_x , center_y + 0.25 * target_h
        )

        self._label_opacity_path = rt.Path(
            1, 1,
            1, 1,
            0, 0
        )

        for path in range(self._label_opacity_path, self._label_path) do
            path:override_parameterization(
                0.6, 0.4
            )
        end

        local m = rt.settings.margin_unit
        self._target_path = rt.Path(
            0, 0,
            5 * m, 0
        )

        if _particle_render_shader == nil then
            _particle_render_shader = rt.Shader("battle/animations/hp_lost_render.glsl")

            local red = rt.Palette.ATTACK
            _particle_render_shader:send("red", {red.r, red.g, red.b})
        end
        self._render_shader = _particle_render_shader

        if _particle_step_shader == nil then
            _particle_step_shader = rt.ComputeShader("battle/animations/hp_lost_step.glsl")
            _particle_step_shader:send("damping_speed", rt.settings.battle.animations.hp_lost.particle_damping_speed)
            _particle_step_shader:send("radius_speed", rt.settings.battle.animations.hp_lost.radius_reduction_speed)
        end
        self._step_shader = _particle_step_shader

        if _particle_mesh == nil then
            _particle_mesh = rt.VertexCircle(0, 0, 1, 1, 16)
            local gray = 0.8;
            _particle_mesh:set_vertex_color(1, rt.RGBA(gray, gray, gray, 1))
        end
        self._mesh = _particle_mesh

        self._particle_buffer = rt.GraphicsBuffer(
            self._step_shader:get_buffer_format("particle_buffer"),
            self._n_particles
        )

        local data = {}
        local velocity = rt.settings.battle.animations.hp_lost.particle_velocity
        local velocity_loss_velocity = rt.settings.battle.animations.hp_lost.particle_damping_ratio

        for i = 1, self._n_particles do
            table.insert(data, {
                center_x, center_y,
                rt.random.number(0, 2 * math.pi), -- angle
                rt.random.number(0.01, 1) * velocity, -- velocity
                0, -- damping
                rt.random.number(0.5, 1), -- hue
                rt.random.number(5, 7),
            })
        end
        self._particle_buffer:replace_data(data)

        self._message_id = self._scene:send_message(self._message, function()
            self._message_done = true
        end)
    end
end

--- @override
function bt.Animation.HP_LOST:finish()
    self._target:set_is_visible(true)
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.HP_LOST:update(delta)
    local is_done = true
    for animation in range(
        self._label_path_animation,
        self._label_scale_animation,
        self._target_path_animation,
        self._shader_weight_animation,
        self._particle_opacity_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end

    self._label_x, self._label_y = self._label_path:at(self._label_path_animation:get_value())
    self._label:set_opacity(select(1, self._label_opacity_path:at(self._label_path_animation:get_value())))

    self._target_offset_x, self._target_offset_y = self._target_path:at(self._target_path_animation:get_value())
    self._shader_weight = self._shader_weight_animation:get_value()
    self._particle_opacity = self._particle_opacity_animation:get_value()

    self._elapsed = self._elapsed + delta
    self._radius_fraction = rt.InterpolationFunctions.BUTTERWORTH_LOWPASS(self._elapsed / self._duration - 0.1, 5)

    self._step_shader:send("particle_buffer", self._particle_buffer)
    self._step_shader:send("delta", delta)
    self._step_shader:dispatch(self._n_particles, 1)

    self._label_scale = self._label_scale_animation:get_value()
    return is_done and self._message_done
end

--- @override
function bt.Animation.HP_LOST:draw()
    love.graphics.push()
    love.graphics.translate(self._target_offset_x, self._target_offset_y)
    self._shader:bind()
    self._shader:send("weight", self._shader_weight)
    self._target:draw_snapshot()
    self._shader:unbind()
    love.graphics.pop()

    self._render_shader:bind()
    self._render_shader:send("particle_buffer", self._particle_buffer._native)
    self._render_shader:send("opacity", self._particle_opacity)
    self._render_shader:send("radius_factor", self._radius_fraction)
    self._mesh:draw_instanced(self._n_particles)
    self._render_shader:unbind()

    love.graphics.push()
    love.graphics.translate(self._label_x, self._label_y)
    love.graphics.scale(self._label_scale, self._label_scale)
    self._label:draw()
    love.graphics.pop()
end