rt.settings.battle.animations.enemy_appeared = {
    duration = 2.5
}

--- @class bt.Animation.ENEMY_APPEARED
bt.Animation.ENEMY_APPEARED = meta.new_type("ENEMY_APPEARED", function(scene, target)
    return meta.new(bt.Animation.ENEMY_APPEARED, {
        _scene = scene,
        _target = target,
        _snapshot = {}, -- rt.SnapshotLayout
        _path = {}, -- rt.Spline
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ENEMY_APPEARED:start()
    self._snapshot = rt.SnapshotLayout()

    local snapshot = self._snapshot
    local target = self._target

    snapshot:realize()
    snapshot:fit_into(target:get_bounds())

    self._target:set_is_visible(true)
    snapshot:snapshot(target)
    self._target:set_is_visible(false)
    snapshot:set_opacity_offset(-1)
    snapshot:set_rgb_offset(-1, -1, -1)

    local bounds = target:get_bounds()
    self._path = rt.Spline({-1 * bounds.width * 2, 0, 0, 0})

    self._scene:send_message("<b>" .. self._target._entity:get_name() .. "</b>" .. " appeared!")
end

--- @override
function bt.Animation.ENEMY_APPEARED:update(delta)
    local duration = rt.settings.battle.animations.enemy_appeared.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local target = self._snapshot
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
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ENEMY_APPEARED:draw()
    self._snapshot:draw()
end