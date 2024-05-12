rt.settings.battle.animations.status_lost = {
    duration = 2
}

--- @class bt.Animation.STATUS_LOST
bt.Animation.STATUS_LOST = meta.new_type("STATUS_LOST", rt.QueueableAnimation, function(target, status)
    return meta.new(bt.Animation.STATUS_LOST, {
        _target = target,
        _status = status,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Label

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.STATUS_LOST:start()
    self._label = rt.Label("<o>Lost:\n<b><mono>" .. self._status:get_name() .. "</mono></b></o>")
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.FOREGROUND)
    self._target_snapshot:set_mix_weight(0)

    local bounds = self._target:get_bounds()
    self._target_snapshot:fit_into(bounds)

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    self._label_path = {}
    local label_w = select(1, self._label:measure()) * 0.5
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.75
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.25
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })
end

--- @override
function bt.Animation.STATUS_LOST:update(delta)
    local duration = rt.settings.battle.animations.status_lost.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    -- label animation
    local label_w, label_h = self._label:measure()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))

    local bounds = self._target:get_bounds()
    self._label:fit_into(
        bounds.x,
        bounds.y + bounds.height - pos_y - 0.5 * label_h,
        bounds.width,
        200
    )

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    return self._elapsed < duration
end

--- @override
function bt.Animation.STATUS_LOST:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.STATUS_LOST:draw()
    self._target_snapshot:draw()
    self._label:draw()
end
