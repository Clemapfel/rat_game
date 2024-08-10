    rt.settings.battle.animations.ally_disappeared = {
    duration = 1.5
}

--- @class bt.Animation.ALLY_DISAPPEARED
bt.Animation.ALLY_DISAPPEARED = meta.new_type("ALLY_DISAPPEARED", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.ALLY_DISAPPEARED, {
        _target = target,
        _snapshot = {}, -- rt.Snapshot
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ALLY_DISAPPEARED:start()
    local snapshot = rt.Snapshot()
    self._snapshot = snapshot
    snapshot:realize()

    local bounds = self._target:get_bounds()
    snapshot:fit_into(bounds)

    self._target:set_is_visible(true)
    snapshot:snapshot(self._target)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.ALLY_DISAPPEARED:update(delta)
    local duration = rt.settings.battle.animations.ally_disappeared.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local snapshot = self._snapshot
    snapshot:set_opacity(1 - fraction)

    return self._elapsed < duration
end

--- @override
function bt.Animation.ALLY_DISAPPEARED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ALLY_DISAPPEARED:draw()
    self._snapshot:draw()
end