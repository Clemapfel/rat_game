rt.settings.battle.animations.status_gained = {
    duration = 2
}

--- @class bt.Animation.STATUS_GAINED
bt.Animation.STATUS_GAINED = meta.new_type("STATUS_GAINED", bt.Animation, function(scene, target, status)
    meta.assert_isa(status, bt.Status)
    return meta.new(bt.Animation.STATUS_GAINED, {
        _scene = scene,
        _target = target,
        _status = status,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Label

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.STATUS_GAINED:start()
    if not self._target:get_is_realized() then
        self._target:realize()
    end

    self._label = rt.Label("<o>Status Gained:\n<b><mono>" .. self._status:get_name() .. "</mono></b></o>")
    self._label:realize()
    self._label_path = {}

    self._target_snapshot = rt.SnapshotLayout()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.FOREGROUND)
    self._target_snapshot:set_mix_weight(0)
    self._target_path = {}

    local bounds = self._target:get_bounds()
    self._target_snapshot:fit_into(bounds)

    local label = self._label
    local label_w = label:get_width() * 0.5
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })

    local offset = 0.05
    self._target_path = rt.Spline({
        --[[
        0, 0,
        -1 * offset, 0,
        offset, 0,
        ]]--
        0, 0,
    })

    local target = self._target
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)
end

--- @override
function bt.Animation.STATUS_GAINED:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.status_gained.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- update once per update for animated battle sprites
    local target = self._target
    target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)

    -- label animation
    local label_w, label_h = self._label:get_size()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))

    local bounds = self._target:get_bounds()
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
    target = self._target_snapshot
    local current = target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sinusoid_ease_in_out(fraction))
    offset_x = offset_x * current.width
    offset_y = offset_y * current.height
    current.x = current.x + offset_x
    current.y = current.y + offset_y
    target:set_position_offset(offset_x, offset_y)
    target:set_mix_weight(rt.symmetrical_linear(fraction, 0.5))

    return self._elapsed < duration
end

--- @override
function bt.Animation.STATUS_GAINED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.STATUS_GAINED:draw()
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._label:draw()
end
