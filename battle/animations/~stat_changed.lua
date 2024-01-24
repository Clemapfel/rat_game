rt.settings.stat_changed_animation = {
    duration = 3,
    particle_size = 40
}

--- @class bt.StatChangedAnimation
--- @param targets Table<rt.Widget>
--- @param directions Table<rt.Direction>
--- @param which_stats Table<bt.Stat>
bt.StatChangedAnimation = meta.new_type("StatChangedAnimation", function(targets, directions, which_stats)

    local n_targets = sizeof(targets)
    assert(sizeof(directions) == n_targets and sizeof(which_stats) == n_targets)
    local out = meta.new(bt.StatChangedAnimation, {
        _n_targets = n_targets,
        _targets = targets,
        _directions = directions,
        _which_stats = which_stats,

        _emitters = {},     -- Table<rt.ParticleEmitter>
        _snapshots = {},    -- Table<rt.SnapshotLayout>
        _overlays = {},      -- Table<rt.OverlayLayout>

        _scale_paths = {},   -- Table<rt.Spline>
        _offset_paths = {},  -- Table<rt.Spline>

        _elapsed = 0
    }, rt.StateQueueState)

    local particle_size = rt.settings.stat_changed_animation.particle_size
    for i = 1, out._n_targets do
        local particle = rt.DirectionIndicator(out._directions[i])
        particle:realize()
        particle:fit_into(0, 0, particle_size, particle_size)

        local emitter = rt.ParticleEmitter(particle)
        table.insert(out._emitters, emitter)

        emitter:set_speed(50)
        emitter:set_particle_lifetime(0, rt.settings.hp_gained_animation.duration)
        emitter:set_scale(1, 1.5)
        emitter:set_density(0)

        local snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, snapshot)

        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        overlay:push_overlay(snapshot)
        overlay:push_overlay(emitter)
    end
    return out
end)

--- @overload
function bt.StatChangedAnimation:start()
    self._scale_paths = {}
    self._offset_paths = {}

    for i = 1, self._n_targets do
        local bounds = self._targets[i]:get_bounds()
        local direction = self._directions[i]

        local offset = rt.Spline({0, 0, 0, 0})
        local scale = rt.Spline({1, 1, 1, 1})
        if direction == rt.Direction.UP then

        elseif direction == rt.Direction.DOWN then

        elseif direction == rt.Direction.NONE then

        else
            rt.error("In bt.StatChangedAnimation: Invalid direction `" .. tostring(direction) .. "`")
        end
        table.insert(self._offset_paths, offset)
        table.insert(self._scale_paths, scale)

        local emitter = self._emitters[i]
        emitter:set_is_animated(true)
        emitter._native:emit(6)

        local overlay = self._overlays[i]
        overlay:realize()
        local target = self._targets[i]
        target:set_is_visible(true)
        overlay:fit_into(target:get_bounds())
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