rt.settings.battle.animations.switch = {
    duration = 1
}

--- @class bt.Animation.SWITCH
bt.Animation.SWITCH = meta.new_type("SWITCH", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.SWITCH, {
        _scene = scene,
        _target = target,
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.SWITCH:start()
    local snapshot = self._target:get_snapshot()
    local target = self._target

    target:set_is_visible(true)
    snapshot:set_mix_color(rt.Palette.WHITE)
    snapshot:set_mix_weight(0)
end

--- @override
function bt.Animation.SWITCH:update(delta)
    local duration = rt.settings.battle.animations.switch.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local snapshot = self._target:get_snapshot()
    snapshot:set_scale(rt.parabolic_increase(1 - fraction), 1)
    return self._elapsed < duration
end

--- @override
function bt.Animation.SWITCH:finish()
    self._target:get_snapshot():reset()
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.SWITCH:draw()
    -- noop
end