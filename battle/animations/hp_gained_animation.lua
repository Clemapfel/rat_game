rt.settings.hp_gained_animation = {
    font = rt.Font(40, "assets/fonts/pixel.ttf"),
    fade_out_fraction = 0.9,    -- in [0, 1], interval after which fade-out beings
    duration = 2, -- seconds
}

--- @class bt.BattleAnimation_hp_gained
--- @param targets Table<bt.Entity>
--- @param value Table<Number>
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
        _labels = {},   -- Table<rt.Label>
        _paths = {},    -- Table<rt.Spline>
        _elapsed = 0,   -- seconds
    }, rt.StateQueueState)

    out._labels = {}
    for i = 1, out._n_targets do
        local label = rt.Label("<o><color=WHITE>+" .. out._values[i] .. "</o></color>")
        local snapshot = rt.SnapshotLayout()
        snapshot:set_child(label)
        table.insert(out._labels, snapshot)
    end
    return out
end)

function bt.HPGainedAnimation:start()
    self._paths = {}
    for i = 1, self._n_targets do
        local label = self._labels[i]
        label:realize()
        local bounds = self._targets[i]:get_bounds()
        local start_x, start_y = bounds.x + bounds.width * 1/2, bounds.y + bounds.height * 0.5
        local finish_x, finish_y = bounds.x + bounds.width * 1/2, bounds.y - bounds.height * 1/3

        table.insert(self._paths, rt.Spline({start_x, start_y, finish_x, finish_y}))
    end
end

function bt.HPGainedAnimation:update(delta)
    local duration = rt.settings.hp_gained_animation.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        local label = self._labels[i]
        local path = self._paths[i]
        local w, h = label:get_size()
        local pos_x, pos_y = path:at(rt.exponential_plateau(fraction)) self._labels[i]:fit_into(pos_x - 0.5 * w, pos_y, w, h)

        local fade_out_target = rt.settings.hp_gained_animation.fade_out_fraction
        if fraction > fade_out_target then
            local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
            label:set_opacity_offset(-v)
        end
    end

    return self._elapsed < duration
end

function bt.HPGainedAnimation:finish()
    -- TODO: set HP value
end

function bt.HPGainedAnimation:draw()
    for _, label in pairs(self._labels) do
        label:draw()
    end
end