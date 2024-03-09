rt.settings.battle_animation.hp_lost = {
    duration = 2, -- seconds
}

--- @class
--- @param targets Table<rt.Widget>
--- @param values Table<Number>
bt.Animation.PLACEHOLDER = meta.new_type("PLACEHOLDER", function(targets, values)
    local n_targets = sizeof(targets)

    local out = meta.new(bt.Animation.PLACEHOLDER, {
        _targets = targets,
        _values = values,
        _n_targets = n_targets,

        _labels = {},       -- Table<rt.Label>
        _label_snapshots = {},    -- Table<rt.SnapshotLayout>
        _color = rt.Palette.YELLOW_2,

        _target_snapshots = {},

        _elapsed = 0,

        _label_paths = {},  -- Table<rt.Spline>
        _target_paths = {}, -- Table<rt.Spline>
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local label = rt.Label("<o><b><mono><color=WHITE>" .. out._values[i] .. "</o></b></mono></color>")
        table.insert(out._labels, label)

        local label_snapshot = rt.SnapshotLayout()
        table.insert(out._label_snapshots, label_snapshot)
        label_snapshot:set_child(label)
        label_snapshot:set_color(out._color)

        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._target_snapshots, target_snapshot)
        target_snapshot:set_mix_color(out._color)
        target_snapshot:set_mix_weight(0)
    end
    return out
end)

-- @overload
function bt.Animation.PLACEHOLDER:start()
    self._label_paths = {}
    for i = 1, self._n_targets do
        self._label_snapshots[i]:realize()
        local label = self._labels[i]
        local label_w, label_h = label:get_size()

        local bounds = self._targets[i]:get_bounds()
        local start_x, start_y = bounds.x + 0.5 * bounds.width - 0.5 * label_w, bounds.y + 0.5  * bounds.height - 0.5 * label_h

        local vertices = {
            start_x, start_y,
            start_x, bounds.y
        }
        table.insert(self._label_paths, rt.Spline(vertices))

        local target = self._targets[i]
        local snapshot = self._target_snapshots[i]
        snapshot:realize()
        snapshot:fit_into(target:get_bounds())
        snapshot:snapshot(target)
        target:set_is_visible(false)

        local offset = 0.1
        table.insert(self._target_paths, rt.Spline({
            0, 0,
            -1 * offset * bounds.width, 0,
            offset * bounds.width, 0,
            0, 0,
        }))
    end
end

--- @overload
function bt.Animation.PLACEHOLDER:update(delta)
    local duration = rt.settings.battle_animation.hp_gained.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        -- label animation
        local label = self._label_snapshots[i]
        local w, h = label:get_size()
        local cutoff = 0.8
        local post_cutoff_acceleration = 1.5
        local label_fraction = ternary(fraction < cutoff, 0, rt.linear((fraction - cutoff) / (1 - cutoff) * post_cutoff_acceleration))
        local pos_x, pos_y = self._label_paths[i]:at(label_fraction)
        label:fit_into(pos_x, pos_y, w, h)

        local fade_out_target = 0.8
        if fraction > fade_out_target then
            local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
            self._label_snapshots[i]:set_opacity_offset(-v)
        end

        local min_scale = 1
        local max_scale = 1.5
        self._label_snapshots[i]:set_scale(mix(min_scale, max_scale, clamp(fraction * 3, 0, 1)))

        -- target animation
        local speed = 2
        local target = self._target_snapshots[i]
        local current = target:get_bounds()
        local offset_x, offset_y = self._target_paths[i]:at(rt.linear(speed * fraction))
        target:set_position_offset(offset_x, offset_y)
        target:set_mix_weight(rt.symmetrical_linear(speed * fraction, 0.6))

        if speed * fraction > 1 then
            target:set_invert(false)
        end
    end

    return self._elapsed < duration
end

--- @overload
function bt.Animation.PLACEHOLDER:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)
    end
end

--- @overload
function bt.Animation.PLACEHOLDER:draw()
    for i = 1, self._n_targets do
        self._target_snapshots[i]:draw()
        self._label_snapshots[i]:draw()
    end
end