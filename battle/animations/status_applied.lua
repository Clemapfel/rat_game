--- @class bt.Animation.STATUS_APPLIED
bt.Animation.STATUS_APPLIED = meta.new_type("STATUS_APPLIED", rt.QueueableAnimation, function(target, status)
    return meta.new(bt.Animation.STATUS_APPLIED, {
        _target = target,
        _status = status,

        _elapsed = 0
    })
end)

--- @override
function bt.Animation.STATUS_APPLIED:start()
    self._target:activate_status(self._status)
end

--- @override
function bt.Animation.STATUS_APPLIED:update(delta)
    local duration = rt.settings.battle.status_bar.activate_animation_duration
    self._elapsed = self._elapsed + delta
    return self._elapsed < duration
end

--- @override
function bt.Animation.STATUS_APPLIED:finish()
    -- noop
end

--- @override
function bt.Animation.STATUS_APPLIED:draw()
    -- noop
end