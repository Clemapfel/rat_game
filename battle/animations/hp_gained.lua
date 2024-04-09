rt.settings.battle.animations.hp_gained = {
    duration = 2
}

--- @class bt.Animation.HP_GAINED
bt.Animation.HP_GAINED = meta.new_type("HP_GAINED", bt.Animation, function(scene, target, value)
    return meta.new(bt.Animation.HP_GAINED, {
        _scene = scene,
        _target = target,
        _value = value,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},           -- rt.Label
        _label_snapshot = {},  -- rt.SnapshotLayout
        _emitter = {},         -- rt.ParticleEmitter
        _overlays = {},        -- rt.OverlayLayout

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.HP_GAINED:start()

    if not self._target:get_is_realized() then
        self._target:realize()
    end
    self._target:set_is_visible(true)

    local particle = rt.Label("<o><color=HP>+</color></o>")
    particle:fit_into(0, 0, 50, 50)
    particle:realize()

    self._label = rt.Label("<o><b><mono><color=WHITE>+" .. self._value .. "</o></b></mono></color>")
    self._label_snapshot = rt.SnapshotLayout()
    self._overlay = rt.OverlayLayout()
    self._emitter = rt.ParticleEmitter(particle)
    self._target_snapshot = rt.SnapshotLayout()

    self._label_snapshot:set_child(self._label)
    self._target_snapshot:set_mix_color(rt.Palette.HP)
    self._target_snapshot:set_mix_weight(0)

    self._overlay:push_overlay(self._target_snapshot)
    self._overlay:push_overlay(self._emitter)
    self._overlay:push_overlay(self._label_snapshot)

    self._emitter:set_speed(50)
    self._emitter:set_particle_lifetime(0, rt.settings.battle.animations.hp_gained.duration)
    self._emitter:set_scale(1, 1.5)
    self._emitter:set_density(0)

    self._label_path = {}
    self._target_path = {}

    local overlay = self._overlay
    overlay:realize()
    local bounds = self._target:get_bounds()
    overlay:fit_into(bounds)

    local label = self._label
    local label_w = label:get_width() * 0.5
    local start_x, start_y = bounds.x + bounds.width * 0.75, bounds.y + bounds.height * (1 - 0.25)
    local finish_x, finish_y = bounds.x + bounds.width * 0.75, bounds.y
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })

    local offset = 0.05
    self._target_path = rt.Spline({
        0, 0,
        -1 * offset, 0,
        offset, 0,
        0, 0,
    })

    local emitter = self._emitter
    emitter:set_is_animated(true)
    emitter._native:emit(6)

    local target = self._target
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)
end

--- @override
function bt.Animation.HP_GAINED:update(delta)
    if not self._is_started then return end

    -- update once per update for animated battle sprites
    local target = self._target
    target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)

    local duration = rt.settings.battle.animations.hp_gained.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- label animation
    local label = self._label_snapshot
    local w, h = label:get_size()
    local pos_x, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))
    label:fit_into(pos_x - 0.5 * w, pos_y, w, h)

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label_snapshot:set_opacity_offset(-v)
    end

    -- target animation
    local target = self._target_snapshot
    local current = target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sinusoid_ease_in_out(fraction))
    offset_x = offset_x * current.width
    offset_y = offset_y * current.height
    current.x = current.x + offset_x
    current.y = current.y + offset_y
    target:set_position_offset(offset_x, offset_y)
    target:set_mix_weight(rt.symmetrical_linear(fraction, 0.3))

    return self._elapsed < duration
end

--- @override
function bt.Animation.HP_GAINED:finish()
    self._target:set_is_visible(true)
    self._emitter:set_is_animated(false)
end

--- @override
function bt.Animation.HP_GAINED:draw()
    --self._overlay:draw()
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._emitter:draw()
    self._label_snapshot:draw()
end