rt.settings.battle_animation.hp_lost = {
    duration = 1, -- seconds
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

        _elapsed = 0,

        _label_paths = {},  -- Table<rt.Spline>
        _label_scales = {}  -- Table<rt.Spline>
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local label = rt.Label("<o><b><mono><color=WHITE>" .. out._values[i] .. "</o></b></mono></color>")
        table.insert(out._labels, label)

        local label_snapshot = rt.SnapshotLayout()
        table.insert(out._label_snapshots, label_snapshot)
        label_snapshot:set_child(label)
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
        local start_x, start_y = bounds.x + 0.5 * bounds.width - 0.5 * label_w, bounds.y + 0.75  * bounds.height - 0.5 * label_h

        local vertices = {
            start_x, start_y,
            start_x, start_y - bounds.height * 1.5
        }
        table.insert(self._label_paths, rt.Spline(vertices))
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
        local cutoff = 0.4 -- hold at position 0 for 0.3 * duration, then simulate exponential fall
        local post_cutoff_acceleration = 1.5
        local label_fraction = ternary(fraction < cutoff, 0, rt.exponential_acceleration((fraction - cutoff) * post_cutoff_acceleration))
        local pos_x, pos_y = self._label_paths[i]:at(label_fraction)
        label:fit_into(pos_x, pos_y, w, h)

        local fade_out_target = 0.8
        if fraction > fade_out_target then
            local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
            self._label_snapshots[i]:set_opacity_offset(-v)
        end

        local min_scale = 1
        local max_scale = 2
        self._label_snapshots[i]:set_scale(mix(min_scale, max_scale, clamp(fraction, 0, 1)))
    end

    return self._elapsed < duration
end

--- @overload
function bt.Animation.PLACEHOLDER:finish()
end

--- @overload
function bt.Animation.PLACEHOLDER:draw()
    for i = 1, self._n_targets do
        self._label_snapshots[i]:draw()
    end
end