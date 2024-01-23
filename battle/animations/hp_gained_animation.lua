rt.settings.hp_gained_animation = {
    font = rt.Font(40, "assets/fonts/pixel.ttf"),
    fade_out_fraction = 0.9,    -- in [0, 1], interval after which fade-out beings
    duration = 2, -- seconds
}

--- @class
--- @param targets Table<rt.Widget>
--- @param values Table<Number>
bt.HPGainedAnimation = meta.new_type("HPGainedAnimation", function(targets, values)
    local n_targets = sizeof(targets)
    if n_targets > 1 then
        meta.assert_table(values)
        assert(sizeof(targets) == sizeof(values))
    end

    local out = meta.new(bt.HPGainedAnimation, {
        _targets = targets,
        _values = values,
        _n_targets = n_targets,

        _labels = {},       -- Table<rt.Label>
        _label_snapshot = {},    -- Table<rt.SnapshotLayout>
        _emitters = {},     -- Table<rt.ParticleEmitter>
        _overlays = {},      -- Table<rt.OverlayLayout>
        _target_snapshots = {},

        _elapsed = 0,

        _label_paths = {},  -- Table<rt.Spline>
        _target_paths = {}, -- Table<rt.Spline>
    }, rt.StateQueueState)

    local particle = rt.Label("<o><color=HP>+</color></o>")
    particle:fit_into(0, 0, 50, 50)
    particle:realize()

    for i = 1, out._n_targets do
        local label = rt.Label("<o><b><mono><color=WHITE>+" .. out._values[i] .. "</o></b></mono></color>")
        table.insert(out._labels, label)

        local label_snapshot = rt.SnapshotLayout()
        table.insert(out._label_snapshot, label_snapshot)

        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        local emitter = rt.ParticleEmitter(particle)
        table.insert(out._emitters, emitter)

        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._target_snapshots, target_snapshot)

        label_snapshot:set_child(label)
        target_snapshot:set_mix_color(rt.Palette.HP)
        target_snapshot:set_mix_weight(0)

        overlay:push_overlay(target_snapshot)
        overlay:push_overlay(emitter)
        overlay:push_overlay(label_snapshot)

        emitter:set_speed(50)
        emitter:set_particle_lifetime(0, rt.settings.hp_gained_animation.duration)
        emitter:set_scale(1, 1.5)
        emitter:set_density(0)
    end
    return out
end)

-- @overload
function bt.HPGainedAnimation:start()
    self._label_paths = {}
    self._target_paths = {}

    for i = 1, self._n_targets do

        local overlay = self._overlays[i]
        overlay:realize()
        local bounds = self._targets[i]:get_bounds()
        overlay:fit_into(bounds)

        local label = self._labels[i]
        local label_w = label:get_width() * 0.5
        local start_x, start_y = bounds.x + bounds.width * 1/2, bounds.y + bounds.height * 0.5
        local finish_x, finish_y = bounds.x + bounds.width * 1/2, bounds.y - bounds.height * 1/3
        table.insert(self._label_paths, rt.Spline({start_x, start_y, finish_x, finish_y}))

        local left_x, left_y = bounds.x + bounds.width * 0.5 - label_w, bounds.y
        local right_x, right_y = bounds.x + bounds.width * 0.5 + label_w, bounds.y
        table.insert(self._target_paths, rt.Spline({
              0, 0,
            -50, 0,
             50, 0,
              0, 0,
        }))

        local emitter = self._emitters[i]
        emitter:set_is_animated(true)
        emitter._native:emit(6)

        local target = self._targets[i]
        self._target_snapshots[i]:snapshot(target)
        target:set_is_visible(false)
    end
end

--- @overload
function bt.HPGainedAnimation:update(delta)
    local duration = rt.settings.hp_gained_animation.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do

        -- label animation
        local label = self._label_snapshot[i]
        local w, h = label:get_size()
        local pos_x, pos_y = self._label_paths[i]:at(rt.exponential_plateau(fraction * 0.9))
        label:fit_into(pos_x - 0.5 * w, pos_y, w, h)

        local fade_out_target = rt.settings.hp_gained_animation.fade_out_fraction
        if fraction > fade_out_target then
            local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
            self._label_snapshot[i]:set_opacity_offset(-v)
        end

        -- target animation
        local target = self._target_snapshots[i]
        local current = target:get_bounds()
        local offset_x, offset_y = self._target_paths[i]:at(rt.sinoid_ease_in_out(fraction))
        current.x = current.x + offset_x
        current.y = current.y + offset_y
        target:set_position_offsets(offset_x, offset_y)
        target:set_mix_weight(rt.symmetrical_linear(fraction, 0.3))
    end

    return self._elapsed < duration
end

--- @overload
function bt.HPGainedAnimation:finish()
    for i = 1, self._n_targets do
        self._targets[i]:set_is_visible(true)
        self._emitters[i]:set_is_animated(false)
    end
end

--- @overload
function bt.HPGainedAnimation:draw()
    for i = 1, self._n_targets do
        self._overlays[i]:draw()
    end
end