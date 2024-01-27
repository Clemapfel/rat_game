rt.settings.battle_animation.enemy_appeared = {
    duration = 3
}

--- @class
--- @param targets Table<rt.Widget>
bt.Animation.ENEMY_APPEARED = meta.new_type("ENEMY_APPEARED", function(targets)

    local out = meta.new(bt.Animation.ENEMY_APPEARED, {
        _targets = targets,
        _n_targets = sizeof(targets),

        _snapshots = {}, -- Table<rt.SnapshotLayout>
        _paths = {},            -- Table<rt.Spline>

        _elapsed = 0,
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, snapshot)
    end
    return out
end)

-- @overload
function bt.Animation.ENEMY_APPEARED:start()
    self._paths = {}
    for i = 1, self._n_targets do

        local target = self._targets[i]
        local snapshot = self._snapshots[i]
        snapshot:realize()
        snapshot:fit_into(target:get_bounds())

        target:set_is_visible(true)
        snapshot:snapshot(target)
        snapshot:set_opacity_offset(-1)
        snapshot:set_rgb_offset(-1, -1, -1)

        target:set_is_visible(false)

        local bounds = target:get_bounds()
        table.insert(self._paths, rt.Spline({-1 * bounds.width * 2, 0, 0, 0}))
    end
end

--- @overload
function bt.Animation.ENEMY_APPEARED:update(delta)
    local duration = rt.settings.battle_animation.enemy_appeared.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        local target = self._snapshots[i]
        local fade_out_end = 0.4

        -- slide in from the left
        target:set_position_offset(self._paths[i]:at(rt.exponential_deceleration(2 * fraction), 0))

        -- fade-in ramp
        if fraction < fade_out_end then
            local v = -1 * (1 - fraction / fade_out_end)
            target:set_opacity_offset(v)
        else
            target:set_opacity_offset(0)
        end

        -- keep black, then fade in to actual color
        local unblacken_start = 0.9
        if fraction >= unblacken_start then
            local v = -1 * clamp((1 - fraction) / (1 - unblacken_start), 0, 1)
            target:set_rgb_offset(v, v, v)
        end
    end

    return self._elapsed < duration
end

--- @overload
function bt.Animation.ENEMY_APPEARED:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)
    end
end

--- @overload
function bt.Animation.ENEMY_APPEARED:draw()
    for i = 1, self._n_targets do
        self._snapshots[i]:draw()
    end
end