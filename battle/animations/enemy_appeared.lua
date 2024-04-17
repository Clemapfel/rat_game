rt.settings.battle.animations.enemy_appeared = {
    duration = 0.1--2.5
}

--- @class bt.Animation.ENEMY_APPEARED
bt.Animation.ENEMY_APPEARED = meta.new_type("ENEMY_APPEARED", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.ENEMY_APPEARED, {
        _scene = scene,
        _target = target,
        _path = {}, -- rt.Spline
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ENEMY_APPEARED:start()
    local snapshot = self._target:get_snapshot()
    local target = self._target

    target:set_is_visible(true)
    snapshot:set_opacity_offset(-1)
    snapshot:set_rgb_offset(-1, -1, -1)

    local bounds = target:get_bounds()
    self._path = rt.Spline({-1 * bounds.width * 2, 0, 0, 0})
end

--- @override
function bt.Animation.ENEMY_APPEARED:update(delta)
    local duration = rt.settings.battle.animations.enemy_appeared.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local target = self._target:get_snapshot()
    local fade_out_end = 0.4

    -- slide in from the left
    target:set_position_offset(self._path:at(1 - rt.exponential_deceleration(2 * fraction), 0))

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

    return self._elapsed < duration
end

--- @override
function bt.Animation.ENEMY_APPEARED:finish()
    self._target:get_snapshot():reset()
end

--- @override
function bt.Animation.ENEMY_APPEARED:draw()
    -- noop
end