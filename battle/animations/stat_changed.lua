rt.settings.battle_animation.STAT_CHANGED = {
    duration = 3
}

--- @class
--- @param targets Table<rt.Widget>
--- @param values Table<Number>
bt.Animation.STAT_CHANGED = meta.new_type("STAT_CHANGED", function(targets, directions, which_stats)
    local n_targets = sizeof(targets)
    local n_targets = sizeof(targets)
    assert(sizeof(directions) == n_targets and sizeof(which_stats) == n_targets)

    local out = meta.new(bt.Animation.STAT_CHANGED, {
        _n_targets = n_targets,
        _targets = targets,
        _directions = directions,
        _which_stats = which_stats,

        _direction_sprites = {},       -- Table<rt.ParticleEmitter>
        _overlays = {},       -- Table<rt.OverlayLayout>
        _direction_snapshots = {},
        _target_snapshots = {},     -- Table<rt.SnapshotLayout>

        _scale_paths = {},   -- Table<rt.Spline>
        _offset_paths = {},  -- Table<rt.Spline>
        _direction_alpha_paths = {}, -- Table<rt.Spline>
        _direction_paths = {}, -- Table<rt.Spline>

        _elapsed = 0,
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local overlay = rt.OverlayLayout()
        table.insert(out._overlays, overlay)

        local direction = out._directions[i]
        local particle = rt.DirectionIndicator(direction)
        assert(direction == rt.Direction.UP or direction == rt.Direction.DOWN)

        local stat = out._which_stats[i]
        local color
        if stat == bt.Stat.ATTACK then
            color = rt.Palette.ATTACK
        elseif stat == bt.Stat.SPEED then
            color = rt.Palette.DEFENSE
        elseif stat == bt.Stat.SPEED then
            color = rt.Palette.SPEED
        end
        particle:set_color(color)

        table.insert(out._direction_sprites, particle)
        local direction_snapshot = rt.SnapshotLayout()
        table.insert(out._direction_snapshots, direction_snapshot)
        
        local target_snapshot = rt.SnapshotLayout()
        table.insert(out._target_snapshots, target_snapshot)
        target_snapshot:set_mix_color(color)
        target_snapshot:set_mix_weight(0)

        overlay:push_overlay(target_snapshot)
        overlay:push_overlay(direction_snapshot)
    end
    return out
end)

-- @overload
function bt.Animation.STAT_CHANGED:start()

    for i = 1, self._n_targets do

        local overlay = self._overlays[i]
        overlay:realize()
        local bounds = self._targets[i]:get_bounds()
        overlay:fit_into(bounds)

        local target = self._targets[i]
        target:set_is_visible(true)
        local target_snapshot = self._target_snapshots[i]
        target_snapshot:snapshot(target)
        target:set_is_visible(false)

        local direction = self._direction_sprites[i]
        direction:realize()
        direction:fit_into(bounds)
        self._direction_snapshots[i]:snapshot(direction)

        local direction = self._directions[i]
        local scale
        if direction == rt.Direction.UP then
            local up_offset = 0.3
            scale = rt.Spline({1, 1, 1 + up_offset, 1 + up_offset, 1, 1})
        elseif direction == rt.Direction.DOWN then
            local down_offset = 0.3
            scale = rt.Spline({1, 1, 1 - down_offset, 1 - down_offset, 1, 1})
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

        local max_alpha = 0.3
        table.insert(self._direction_alpha_paths, rt.Spline({
            0, 0, max_alpha, max_alpha, 0, 0
        }))

        if direction == rt.Direction.UP then
            table.insert(self._direction_paths, rt.Spline({
                0, 0.5,
                0, -0.5,
                0, -1
            }))
        elseif direction == rt.Direction.DOWN then
            table.insert(self._direction_paths, rt.Spline({
                0, 0,
                0, 0.5,
                0, 1
            }))
        end
    end
end

--- @overload
function bt.Animation.STAT_CHANGED:update(delta)
    local duration = rt.settings.battle_animation.STAT_CHANGED.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        local snapshot = self._target_snapshots[i]

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
        snapshot:set_mix_weight(rt.symmetrical_linear(fraction, 0.1))

        -- slide direction indicator
        local direction = self._direction_snapshots[i]
        local bounds = direction:get_bounds()
        local opacity_offset = -1 * (1 - self._direction_alpha_paths[i]:at(rt.linear(fraction)))
        direction:set_opacity_offset(opacity_offset)
        local offset_x, offset_y = self._direction_paths[i]:at(rt.linear(fraction))
        offset_x = offset_x * 0.5 * bounds.width
        offset_y = offset_y * 0.5 * bounds.height
        direction:set_position_offset(offset_x, offset_y)
    end

    return self._elapsed < duration
end

--- @overload
function bt.Animation.STAT_CHANGED:finish()
    for i = 1, self._n_targets do
        self._targets[i]:set_is_visible(true)
    end
end

--- @overload
function bt.Animation.STAT_CHANGED:draw()
    local fraction = self._elapsed / rt.settings.battle_animation.STAT_CHANGED.duration
    for i = 1, self._n_targets do
       self._overlays[i]:draw()
    end
end