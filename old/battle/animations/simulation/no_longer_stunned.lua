rt.settings.battle.animations.no_longer_stunned = {
    duration = 0.5
}

--- @class bt.Animation.NO_LONGER_STUNNED
bt.Animation.NO_LONGER_STUNNED = meta.new_type("NO_LONGER_STUNNED", rt.QueueableAnimation, function(target)
    return meta.new(bt.Animation.NO_LONGER_STUNNED, {
        _target = target,

        _target_snapshot = {}, -- rt.Snapshot
        _label = {},          -- rt.Glyph

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.NO_LONGER_STUNNED:start()
    self._label = rt.Label("<o><b>NO LONGER STUNNED</b></o>")
    self._label:realize()
    self._label:set_justify_mode(rt.JustifyMode.CENTER)

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:fit_into(self._target:get_bounds())
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local bounds = self._target:get_bounds()
    for widget in range(self._label, self._target_snapshot) do
        widget:fit_into(bounds)
    end

    local label_w = select(1, self._label:measure()) * 0.5
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.25
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.5
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })

    local offset = 10
    local target_path = {
        0, 0,
        0, -offset,
        0, offset,
        0, 0,
    }

    self._target_path = rt.Spline(target_path)
end

--- @override
function bt.Animation.NO_LONGER_STUNNED:update(delta)
    local duration = rt.settings.battle.animations.no_longer_stunned.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- label animation
    local bounds = self._target:get_bounds()
    local label_w, label_h = self._label:get_size()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))

    self._label:fit_into(
        bounds.x + 0.5 * bounds.width - 0.5 * label_w,
        bounds.y + bounds.height - pos_y - 0.5 * label_h,
        bounds.width,
        200
    )

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    -- target animation
    local current = self._target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sigmoid(fraction))
    self._target_snapshot:set_position_offset(offset_x, offset_y)

    return self._elapsed < duration
end

--- @override
function bt.Animation.NO_LONGER_STUNNED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.NO_LONGER_STUNNED:draw()
    self._target_snapshot:draw()
    self._label:draw()
end
