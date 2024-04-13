rt.settings.battle.animations.killed = {
    duration = 2
}

--- @class bt.Animation.KILLED
bt.Animation.KILLED = meta.new_type("KILLED", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.KILLED, {
        _scene = scene,
        _target = target,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Label

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.KILLED:start()
    if not self._target:get_is_realized() then
        self._target:realize()
    end
    self._target:set_ui_is_visible(true)

    self._label = rt.Label("<o><b><outline_color=TRUE_WHITE><color=BLACK>KILLED</color></b></o></outline_color>")
    self._label:realize()
    self._label_path = {}

    self._target_snapshot = rt.SnapshotLayout()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.TRUE_BLACK)
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

    local target = self._target
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)
end

--- @override
function bt.Animation.KILLED:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.killed.duration
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
        rt.graphics.get_width(),
        rt.graphics.get_height()
    )

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    -- fade out happens, then "KILLED" stays on screen
    fraction = fraction * 1.4

    self._target_snapshot:set_mix_weight(fraction)

    local opacity = rt.squish(4, rt.exponential_deceleration, fraction - (0.99 - 0.5))
    target:set_opacity(opacity)

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
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._label:draw()
end
