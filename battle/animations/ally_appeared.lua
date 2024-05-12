rt.settings.battle.animations.ally_appeared = {
    duration = 2.5
}

--- @class bt.Animation.ALLY_APPEARED
bt.Animation.ALLY_APPEARED = meta.new_type("ALLY_APPEARED", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.ALLY_APPEARED, {
        _target = target,
        _snapshot = {}, -- rt.Snapshot
        _path = {},
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ALLY_APPEARED:start()
    local snapshot = rt.Snapshot()
    self._snapshot = snapshot
    snapshot:realize()

    local bounds = self._target:get_bounds()
    snapshot:fit_into(bounds)

    self._target:set_is_visible(true)
    snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    snapshot:set_opacity_offset(-1)
    snapshot:set_rgb_offset(-1, -1, -1)

    local m = rt.settings.margin_unit
    self._path = rt.Spline({
        0, -1 * (bounds.y - (rt.graphics.get_height() + bounds.height + m)),
        0, 0
    })
end

--- @override
function bt.Animation.ALLY_APPEARED:update(delta)
    local duration = rt.settings.battle.animations.ally_appeared.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local snapshot = self._snapshot
    local fade_out_end = 0.4

    self._target:set_is_visible(true)
    snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    -- slide in from the left
    snapshot:set_position_offset(self._path:at(rt.reverse_parabolic_increase(fraction), 0))

    -- fade-in ramp
    if fraction < fade_out_end then
        local v = -1 * (1 - fraction / fade_out_end)
        snapshot:set_opacity_offset(v)
    else
        snapshot:set_opacity_offset(0)
    end

    -- keep black, then fade in to actual color
    local unblacken_start = 0.9
    if fraction >= unblacken_start then
        local v = -1 * clamp((1 - fraction) / (1 - unblacken_start), 0, 1)
        snapshot:set_rgb_offset(v, v, v)
    end

    return self._elapsed < duration
end

--- @override
function bt.Animation.ALLY_APPEARED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ALLY_APPEARED:draw()
    self._snapshot:draw()
end