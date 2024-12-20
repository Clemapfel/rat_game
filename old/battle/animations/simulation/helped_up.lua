rt.settings.battle.animations.helped_up = {
    duration = 2
}

--- @class bt.Animation.HELPED_UP
bt.Animation.HELPED_UP = meta.new_type("HELPED_UP", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.HELPED_UP, {
        _target = target,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Label

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.HELPED_UP:start()

    self._label = rt.Label("<<o><b><color=MINT_1>Got Up</color></b></o>")
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.MINT_1)
    self._target_snapshot:set_mix_weight(0)

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local bounds = self._target:get_bounds()
    for widget in range(self._label, self._target_snapshot) do
        widget:fit_into(bounds)
    end

    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })
end

--- @override
function bt.Animation.HELPED_UP:update(delta)
    local duration = rt.settings.battle.animations.helped_up.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local label_w, label_h = self._label:measure()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))
    local bounds = self._target:get_bounds()
    self._label:fit_into(
        bounds.x,
        bounds.y + bounds.height - pos_y - 0.5 * label_h,
        bounds.width, bounds.height
    )

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    self._target_snapshot:set_mix_weight(rt.symmetrical_linear(fraction, 0.5))

    return self._elapsed < duration
end

--- @override
function bt.Animation.HELPED_UP:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.HELPED_UP:draw()
    self._target_snapshot:draw()
    self._label:draw()
end
