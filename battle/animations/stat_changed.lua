rt.settings.stat_changed_animation = {
    duration = 3,
    particle_size = 100
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
        _snapshots = {}, -- Table<rt.SnapshotLayout>

        _scale_paths = {},   -- Table<rt.Spline>
        _offset_paths = {},  -- Table<rt.Spline>

        _elapsed = 0,
    }, rt.StateQueueState)

    local particle_size = rt.settings.stat_changed_animation.particle_size
    for i = 1, out._n_targets do
        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        local particle = rt.DirectionIndicator(out._directions[i])

        local stat = out._which_stats[i]
        if stat == bt.Stat.ATTACK then
            particle:set_color(rt.Palette.ATTACK)
        elseif stat == bt.Stat.SPEED then
            particle:set_color(rt.Palette.DEFENSE)
        elseif stat == bt.Stat.SPEED then
            particle:set_color(rt.Palette.SPEED)
        end

        particle:realize()
        particle:fit_into(0, 0, particle_size, particle_size)

        local emitter = rt.ParticleEmitter(particle)
        table.insert(out._emitters, emitter)

        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, target_snapshot)

        target_snapshot:set_mix_color(rt.Palette.HP)
        target_snapshot:set_mix_weight(0)

        overlay:push_overlay(target_snapshot)
        overlay:push_overlay(emitter)

        emitter:set_speed(50)
        emitter:set_particle_lifetime(0, rt.settings.stat_changed_animation.duration)
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
        if self._directions[i] ~= rt.Direction.NONE then
            emitter._native:emit(1)
        end

        local target = self._targets[i]
        target:set_is_visible(true)
        self._snapshots[i]:snapshot(target)
        target:set_is_visible(false)

        local direction = self._directions[i]
        local scale
        if direction == rt.Direction.UP then
            local up_offset = 0.3
            scale = rt.Spline({1, 1, 1 + up_offset, 1 + up_offset, 1, 1})
        elseif direction == rt.Direction.DOWN then
            local down_offset = 0.3
            scale = rt.Spline({1, 1, 1 - down_offset, 1 - down_offset, 1, 1})
        else
            scale = rt.Spline({1, 1, 1, 1})
        end
        table.insert(self._scale_paths, scale)

        local shake
        if direction == rt.Direction.DOWN then
            shake = rt.Spline({
                 0, 0,
                -1, 0,
                 1, 0,
                -1, 0,
                 1, 0,
                -1, 0,
                 0, 0
            })
        else
            shake = rt.Spline({0, 0, 0, 0})
        end
        table.insert(self._offset_paths, shake)
    end
end

--- @overload
function bt.StatChangedAnimation:update(delta)
    local duration = rt.settings.stat_changed_animation.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        local snapshot = self._snapshots[i]

        -- scale
        snapshot:set_origin(0.5, 1)
        snapshot:set_scale(self._scale_paths[i]:at(rt.exponential_plateau(fraction)))

        -- shake only during middle of scale animation
        local shake_left = 0.45
        local shake_right = 0.55
        if fraction > shake_left and fraction < shake_right then
            local shake_fraction = (fraction - shake_left) / (shake_right - shake_left)
            local offset_x, offset_y = self._offset_paths[i]:at(rt.linear(shake_fraction))
            offset_x = offset_x * snapshot:get_bounds().width * 0.1
            snapshot:set_position_offset(offset_x, offset_y)
        else
            snapshot:set_position_offset(0, 0)
        end
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
    local fraction = self._elapsed / rt.settings.stat_changed_animation.duration
    for i = 1, self._n_targets do
       self._overlays[i]:draw()
    end
end