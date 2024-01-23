rt.settings.hp_lost_animation = {
    duration = 1, -- seconds
}

--- @class
--- @param targets Table<rt.Widget>
--- @param values Table<Number>
bt.HPLostAnimation = meta.new_type("HPLostAnimation", function(targets, values)
    local n_targets = sizeof(targets)
    if n_targets > 1 then
        meta.assert_table(values)
        assert(sizeof(targets) == sizeof(values))
    end

    local out = meta.new(bt.HPLostAnimation, {
        _targets = targets,
        _values = values,
        _n_targets = n_targets,

        _labels = {},       -- Table<rt.Label>
        _label_snapshot = {},    -- Table<rt.SnapshotLayout>
        _overlays = {},      -- Table<rt.OverlayLayout>
        _target_snapshots = {},

        _elapsed = 0,

        _label_paths = {},  -- Table<rt.Spline>
        _target_paths = {}, -- Table<rt.Spline>
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local label = rt.Label("<o><b><mono><color=WHITE>-" .. out._values[i] .. "</o></b></mono></color>")
        table.insert(out._labels, label)

        local label_snapshot = rt.SnapshotLayout()
        table.insert(out._label_snapshot, label_snapshot)

        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._target_snapshots, target_snapshot)

        label_snapshot:set_child(label)
        target_snapshot:set_mix_color(rt.Palette.RED)
        target_snapshot:set_mix_weight(0)

        overlay:push_overlay(target_snapshot)
        overlay:push_overlay(label_snapshot)
    end
    return out
end)

-- @overload
function bt.HPLostAnimation:start()
    self._label_paths = {}
    self._target_paths = {}

    for i = 1, self._n_targets do

        local overlay = self._overlays[i]
        overlay:realize()
        local bounds = self._targets[i]:get_bounds()
        overlay:fit_into(bounds)

        local label = self._labels[i]
        local label_w = label:get_width() * 0.5
        local start_x, start_y = bounds.x + bounds.width * 0.5, bounds.y
        local vertices = {}
        do -- path of label, simulates object accelerating as it is falling
            local n = 10
            local factor = 10
            local f = function(x)
                return (x - 0.3)^2 * 2
            end
            for j = 1, n+10 do
                local x = j / n
                local y = f(x)
                table.insert(vertices, start_x + 2 * factor * x)
                table.insert(vertices, start_y + 10 * factor * y)
            end
        end
        table.insert(self._label_paths, rt.Spline(vertices))

        local left_x, left_y = bounds.x + bounds.width * 0.5 - label_w, bounds.y
        local right_x, right_y = bounds.x + bounds.width * 0.5 + label_w, bounds.y
        table.insert(self._target_paths, rt.Spline({
            0, 0,
            20, 0,
            50, 0,
            0, 0,
        }))

        local target = self._targets[i]
        local snapshot = self._target_snapshots[i]
        snapshot:snapshot(target)
        target:set_is_visible(false)
        snapshot:set_invert(true)
    end
end

--- @overload
function bt.HPLostAnimation:update(delta)
    local duration = rt.settings.hp_gained_animation.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do

        -- label animation
        local label = self._label_snapshot[i]
        local w, h = label:get_size()
        local cutoff = 0.4 -- hold at position 0 for 0.3 * duration, then simulate exponential fall
        local post_cutoff_acceleration = 1.5
        local label_fraction = ternary(fraction < cutoff, 0, rt.exponential_acceleration((fraction - cutoff) * post_cutoff_acceleration))
        local pos_x, pos_y = self._label_paths[i]:at(label_fraction)
        label:fit_into(pos_x - 0.5 * w, pos_y, w, h)

        local fade_out_target = 0.8
        if fraction > fade_out_target then
            local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
            self._label_snapshot[i]:set_opacity_offset(-v)
        end

        -- target animation
        local speed = 5
        local target = self._target_snapshots[i]
        local current = target:get_bounds()
        local offset_x, offset_y = self._target_paths[i]:at(rt.linear(speed * fraction))
        current.x = current.x + offset_x
        current.y = current.y + offset_y
        target:set_position_offset(offset_x, offset_y)
        target:set_mix_color(rt.Palette.RED)
        --target:set_mix_weight(rt.symmetrical_linear(speed * fraction, 0.6))

        if speed * fraction > 1 then
            target:set_invert(false)
        end
    end

    return self._elapsed < duration
end

--- @overload
function bt.HPLostAnimation:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)

        local snapshot = self._target_snapshots[i]
        snapshot:set_invert(false)
    end
end

--- @overload
function bt.HPLostAnimation:draw()
    for i = 1, self._n_targets do
        self._overlays[i]:draw()
    end
end