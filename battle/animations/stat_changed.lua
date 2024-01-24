rt.settings.stat_changed_animation = {
    duration = 3,
    particle_size = 40
}

--- @class
--- @param targets Table<rt.Widget>
--- @param values Table<Number>
bt.StatChangedAnimation = meta.new_type("StatChangedAnimation", function(targets, directions, which_stats)
    local n_targets = sizeof(targets)
    local n_targets = sizeof(targets)
    assert(sizeof(directions) == n_targets and sizeof(which_stats) == n_targets)

    local out = meta.new(bt.StatChangedAnimation, {
        _n_targets = n_targets,
        _targets = targets,
        _directions = directions,
        _which_stats = which_stats,

        _emitters = {},         -- Table<rt.ParticleEmitter>
        _overlays = {},         -- Table<rt.OverlayLayout>
        _target_snapshots = {}, -- Table<rt.SnapshotLayout>

        _elapsed = 0,
    }, rt.StateQueueState)

    local particle_size = rt.settings.stat_changed_animation.particle_size
    for i = 1, out._n_targets do
        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        local particle = rt.DirectionIndicator(out._directions[i])
        particle:realize()
        particle:fit_into(0, 0, particle_size, particle_size)

        local emitter = rt.ParticleEmitter(particle)
        table.insert(out._emitters, emitter)

        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._target_snapshots, target_snapshot)

        target_snapshot:set_mix_color(rt.Palette.HP)
        target_snapshot:set_mix_weight(0)

        overlay:push_overlay(target_snapshot)
        overlay:push_overlay(emitter)

        emitter:set_speed(50)
        emitter:set_particle_lifetime(0, rt.settings.hp_gained_animation.duration)
        emitter:set_scale(1, 1)
        emitter:set_color(rt.RGBA(1, 1, 1, 0.5))
        emitter:set_density(0)
    end
    return out
end)

-- @overload
function bt.StatChangedAnimation:start()

    for i = 1, self._n_targets do

        local overlay = self._overlays[i]
        overlay:realize()
        local bounds = self._targets[i]:get_bounds()
        overlay:fit_into(bounds)

        local emitter = self._emitters[i]
        emitter:set_is_animated(true)
        --emitter._native:emit(6)

        local target = self._targets[i]
        self._target_snapshots[i]:snapshot(target)
        target:set_is_visible(false)
    end
end

--- @overload
function bt.StatChangedAnimation:update(delta)
    local duration = rt.settings.hp_gained_animation.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    for i = 1, self._n_targets do
    end

    return self._elapsed < duration
end

--- @overload
function bt.StatChangedAnimation:finish()
    for i = 1, self._n_targets do
        self._targets[i]:set_is_visible(true)
        self._emitters[i]:set_is_animated(false)
    end
end

--- @overload
function bt.StatChangedAnimation:draw()
    for i = 1, self._n_targets do
        self._overlays[i]:draw()
    end
end