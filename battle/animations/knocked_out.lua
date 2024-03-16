rt.settings.battle.animations.knocked_out = {
    sustain_cycle_duration = 2,
}

--- @class bt.Animation.KNOCKED_OUT
bt.Animation.KNOCKED_OUT_SUSTAIN = meta.new_type("KNOCKED_OUT_SUSTAIN", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.KNOCKED_OUT_SUSTAIN, {
        _scene = scene,
        _target = target,

        _snapshot = {}, -- rt.SnapshotLayout
        _elapsed = 0,

        _target_path = {},
        _mix_path = {},
        _is_active = true
    })
end)

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:start()
    self._snapshot = rt.SnapshotLayout()
    self._snapshot:realize()
    self._snapshot:fit_into(self._target:get_bounds())
    self._snapshot:snapshot(self._target)

    local vertices = {0, 0}
    local n_shakes = 5
    for _ = 1, n_shakes do
        for p in range(-1, 0, 1, 0, 0, 0) do
            table.insert(vertices, p)
        end
    end
    self._target_path = rt.Spline(vertices)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:update(delta)
    self._elapsed = self._elapsed + delta

    local duration = rt.settings.battle.animations.knocked_out.sustain_cycle_duration
    local fraction = (self._elapsed % duration) / duration
    self._snapshot:snapshot(self._target)
    self._snapshot:set_position_offset(self._target_path:at(fraction))
    return true -- sic, needs to be `finish`ed manually
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:draw()
    if self._is_started then
        self._snapshot:draw()
    end
end