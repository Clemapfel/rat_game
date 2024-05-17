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
    -- calculate scale animation duration of bt.StatusBar
    local duration = (rt.settings.ordered_box.max_scale - 1) * 2 / rt.settings.ordered_box.scale_speed
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