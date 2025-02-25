rt.settings.battle.animations.switch = {
    duration = 1
}

--- @class bt.Animation.SWITCH
bt.Animation.SWITCH = meta.new_type("SWITCH", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.SWITCH, {
        _target = target,
        _target_snapshot = {}, -- rt.Snapshot
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.SWITCH:start()
    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:fit_into(self._target:get_bounds())
    self._target_snapshot:set_mix_color(rt.Palette.WHITE)
    self._target_snapshot:set_mix_weight(0)
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.SWITCH:update(delta)
    local duration = rt.settings.battle.animations.switch.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    self._target_snapshot:set_scale(rt.parabolic_increase(1 - fraction), 1)
    return self._elapsed < duration
end

--- @override
function bt.Animation.SWITCH:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.SWITCH:draw()
    self._target_snapshot:draw()
end