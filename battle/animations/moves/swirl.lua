rt.settings.battle.animations.swirl = {
    duration = 1.5,
    shader_path = "battle/animations/moves/swirl.glsl"
}

--- @class bt.Animation.SWIRL
bt.Animation.SWIRL = meta.new_type("SWIRL", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.SWIRL, {
        _target = target,
        _snapshot = {}, -- rt.Snapshot
        _shader = {},  -- rt.Shader
        _elapsed = 0
    })
end)

bt.Animation.SWIRL._shader = rt.Shader(rt.settings.battle.animations.swirl.shader_path)

--- @override
function bt.Animation.SWIRL:start()
    local snapshot = rt.Snapshot()
    self._snapshot = snapshot
    snapshot:realize()
    snapshot:fit_into(self._target:get_bounds())

    self._target:set_is_visible(true)
    snapshot:snapshot(self._target)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.SWIRL:update(delta)
    local duration = rt.settings.battle.animations.swirl.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    self._target:set_is_visible(true)
    self._snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local bounds = self._snapshot:get_bounds()
    self._shader:send("fraction", fraction)
    return self._elapsed < duration
end

--- @override
function bt.Animation.SWIRL:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.SWIRL:draw()
    self._shader:bind()
    self._snapshot:draw_canvas()
    self._shader:unbind()
end