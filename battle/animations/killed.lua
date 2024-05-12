rt.settings.battle.animations.killed = {
    duration = 2
}

--- @class bt.Animation.KILLED
bt.Animation.KILLED = meta.new_type("KILLED", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.KILLED, {
        _target = target,

        _target_snapshot = {}, -- rt.Snapshot
        _label = {},           -- rt.Label

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.KILLED:start()
    self._target:set_ui_is_visible(true)

    self._label = rt.Label("<o><b><outline_color=TRUE_WHITE><color=BLACK>KILLED</color></b></o></outline_color>")
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.TRUE_BLACK)
    self._target_snapshot:set_mix_weight(0)
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local bounds = self._target:get_bounds()
    for widget in range(self._label, self._target_snapshot) do
        widget:fit_into(bounds)
    end

    local label_w = select(1, self._label:measure()) * 0.5
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })
end

--- @override
function bt.Animation.KILLED:update(delta)
    local duration = rt.settings.battle.animations.killed.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local label_w, label_h = self._label:get_size()
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

    fraction = fraction * 1.4 -- fade out happens, then "KILLED" stays on screen

    local opacity = rt.squish(4, rt.exponential_deceleration, fraction - (0.99 - 0.5))
    self._target_snapshot:set_opacity(opacity)
    self._target_snapshot:set_mix_weight(fraction)

    if fraction >= 1 then
        self._target:set_is_visible(true)
        self._target:set_ui_is_visible(false)
    end

    return self._elapsed < duration
end

--- @override
function bt.Animation.KILLED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.KILLED:draw()
    self._target_snapshot:draw()
    self._label:draw()
end