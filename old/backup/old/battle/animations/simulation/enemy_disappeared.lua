rt.settings.battle.animations.enemy_disappeared = {
    duration = 1.5
}

--- @class bt.Animation.ENEMY_DISAPPEARED
bt.Animation.ENEMY_DISAPPEARED = meta.new_type("ENEMY_DISAPPEARED", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.ENEMY_DISAPPEARED, {
        _target = target,
        _snapshot = {}, -- rt.Snapshot
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ENEMY_DISAPPEARED:start()
    local snapshot = rt.Snapshot()
    self._snapshot = snapshot
    snapshot:realize()
    snapshot:set_mix_color(rt.Palette.TRUE_BLACK)

    local bounds = self._target:get_bounds()
    snapshot:fit_into(bounds)

    self._target:set_is_visible(true)
    snapshot:snapshot(self._target)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.ENEMY_DISAPPEARED:update(delta)
    local duration = rt.settings.battle.animations.enemy_disappeared.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local snapshot = self._snapshot
    snapshot:set_mix_weight(1.5 * rt.sqrt_acceleration(fraction))
    snapshot:set_opacity(1 - fraction)
    self._target:set_opacity(1 - fraction)

    return self._elapsed < duration
end

--- @override
function bt.Animation.ENEMY_DISAPPEARED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ENEMY_DISAPPEARED:draw()
    self._snapshot:draw()
end