rt.settings.battle.animations.hp_gained = {
    duration = 3,
}

--- @class bt.Animation.HP_GAINED
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
--- @param value Number
bt.Animation.HP_GAINED = meta.new_type("HP_GAINED", rt.Animation, function(scene, sprite, value)
    local settings = rt.settings.battle.animations.hp_gained
    return meta.new(bt.Animation.HP_GAINED, {
        _scene = scene,
        _target = sprite,
        _value = value,

        _label = nil, -- rt.Label
        _label_path = nil, -- rt.Path
        _label_path_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SIGMOID, 7
        ),
        _label_opacity_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SHELF_EASE_OUT
        ),
        _label_x = 0,
        _label_y = 0,

        _target_path = nil, -- rt.Path
        _target_path_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SIGMOID, 4.5
        ),
        _target_offset_x = 0,
        _target_offset_y = 0,

        _particle_emitter = nil, -- rt.ParticlEmitter
        _particle = nil, -- rt.Label
        _duration = settings.duration,

        _color_gradient_shader = rt.Shader("battle/animations/hp_gained.glsl"),
        _color_gradient_animation = rt.TimedAnimation(
            settings.duration, 1, 1 - 0.3,
            rt.InterpolationFunctions.BUTTERWORTH, 4
        )
    })
end)

--- @override
function bt.Animation.HP_GAINED:start()
    self._label = rt.Label(
        "<b><o><color=HP>" .. self._value .. "</color></o></b>",
        rt.settings.font.default_large,
        rt.settings.font.default_mono_large
    )
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()
    local label_w, label_h = self._label:measure()
    self._label:fit_into(-0.5 * label_w, -0.5 * label_h)

    local target_x, target_y = self._target:get_position()
    local target_w, target_h = self._target:measure()
    local center_x, center_y = target_x + 0.5 * target_w, target_y + 0.5 * target_h
    local offset = 0.25 * target_h
    self._label_path = rt.Path(
        center_x, center_y,
        center_x, center_y - offset
    )

    local m = rt.settings.margin_unit
    self._target_path = rt.Path(
        0, 0,
        -2 * m, 0,
         2 * m, 0,
        0, 0
    )

    self._particle = rt.Label(
        "<b><o><mono><color=HP>+</color></mono></o></b>",
        rt.settings.font.default_large,
        rt.settings.font.default_mono_large
    )
    self._particle:realize()
    self._particle:fit_into(0, 0)

    local particle_w, particle_h = self._particle:measure()
    local padding = rt.settings.margin_unit
    local texture = rt.RenderTexture(particle_w + 2 * padding, particle_h + 2 * padding)
    love.graphics.push()
    love.graphics.origin()
    texture:bind()
    love.graphics.translate(padding, padding)
    self._particle:draw()
    texture:unbind()
    love.graphics.pop()

    self._particle_emitter = rt.ParticleEmitter(texture)
    self._particle_emitter:realize()
    local frame = 2 * padding
    self._particle_emitter:fit_into(
        target_x + frame,
        target_y + frame,
        target_w - 2 * frame,
        target_h - 2 * frame
    )
    self._particle_emitter:set_emission_rate(7 / self._duration)
    self._particle_emitter:set_linear_velocity(0, -2 * padding)

    local darkening = 0.7
    self._particle_emitter:set_color(rt.RGBA(darkening, darkening, darkening, 1))
    self._particle_emitter:emit(3)

    self._color_gradient_shader:send("color", {rt.color_unpack(rt.Palette.HP)})
    self._color_gradient_shader:send("weight", 0)

    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.HP_GAINED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.HP_GAINED:update(delta)
    local is_done = true
    for animation in range(
        self._label_path_animation,
        self._label_opacity_animation,
        self._target_path_animation,
        self._color_gradient_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end

    self._target_offset_x, self._target_offset_y = self._target_path:at(self._target_path_animation:get_value())

    self._label_x, self._label_y = self._label_path:at(self._label_path_animation:get_value())
    local opacity = self._label_opacity_animation:get_value()
    self._label:set_opacity(opacity)
    self._particle_emitter:set_opacity(opacity)
    self._particle_emitter:update(delta)

    self._color_gradient_shader:send("weight", self._color_gradient_animation:get_value())
    return is_done
end

--- @override
function bt.Animation.HP_GAINED:draw()
    love.graphics.push()
    love.graphics.translate(self._target_offset_x, self._target_offset_y)
    self._color_gradient_shader:bind()
    self._target:draw_snapshot()
    self._color_gradient_shader:unbind()
    love.graphics.pop()

    self._particle_emitter:draw()

    love.graphics.push()
    love.graphics.translate(self._label_x, self._label_y)
    self._label:draw()
    love.graphics.pop()
end