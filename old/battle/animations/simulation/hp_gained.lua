rt.settings.battle.animations.hp_gained = {
    duration = 2
}


--- @class bt.Animation.HP_GAINED
bt.Animation.HP_GAINED = meta.new_type("HP_GAINED", rt.QueueableAnimation, function(target, value)
    return meta.new(bt.Animation.HP_GAINED, {
        _target = target,
        _value = value,

        _target_snapshot = {}, -- rt.Snapshot
        _label = {},           -- rt.Label

        _already_emitted = false,
        _emitter = {},         -- rt.ParticleEmitter

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.HP_GAINED:start()
    local particle = rt.Label("<o><color=HP>+</color></o>")
    particle:fit_into(0, 0, 50, 50)
    particle:realize()

    self._label = rt.Label("<o><b><mono><color=WHITE>+" .. self._value .. "</o></b></mono></color>")
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.HP)
    self._target_snapshot:set_mix_weight(0)
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    self._emitter = rt.ParticleEmitter(particle)
    self._emitter:realize()
    self._emitter:set_speed(50)
    self._emitter:set_particle_lifetime(0, rt.settings.battle.animations.hp_gained.duration)
    self._emitter:set_scale(1, 1.5)
    self._emitter:set_density(0)

    self._label_path = {}
    self._target_path = {}

    local bounds = self._target:get_bounds()
    for widget in range(self._label, self._target_snapshot, self._emitter) do
        widget:fit_into(bounds)
    end

    local label_w = select(1, self._label:measure()) * 0.5
    local start_x, start_y = bounds.x + bounds.width * 0.75, bounds.y + bounds.height * (1 - 0.25)
    local finish_x, finish_y = bounds.x + bounds.width * 0.75, bounds.y
    self._label_path = rt.Spline({ start_x, start_y, finish_x, finish_y })

    local offset = 3 * rt.settings.margin_unit
    self._target_path = rt.Spline({
        0, 0,
        -1 * offset, 0,
        offset, 0,
        0, 0,
    })
end

--- @override
function bt.Animation.HP_GAINED:update(delta)
    local duration = rt.settings.battle.animations.hp_gained.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    if self._already_emitted == false then
        self._emitter:emit(6)
        self._already_emitted = true
    end

    self._emitter:update(delta)
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local bounds = self._target:get_bounds()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))
    self._label:fit_into(bounds.x, pos_y, bounds.width, bounds.height)

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    local current = self._target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sinusoid_ease_in_out(fraction))
    self._target_snapshot:set_position_offset(offset_x, offset_y)
    self._target_snapshot:set_mix_weight(rt.symmetrical_linear(fraction, 0.3))

    return self._elapsed < duration
end

--- @override
function bt.Animation.HP_GAINED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.HP_GAINED:draw()
    self._target_snapshot:draw()
    self._emitter:draw()
    self._label:draw()
end