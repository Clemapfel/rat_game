--- @class bt.Animation.CONSUMABLE_APPLIED
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", rt.QueueableAnimation, function(target, status)
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _target = target,
        _status = status,

        _elapsed = 0
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    self._target:activate_consumable(self._status)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:update(delta)
    -- calculate scale animation duration of bt.StatusBar
    local duration = (rt.settings.ordered_box.max_scale - 1) * 2 / rt.settings.ordered_box.scale_speed
    self._elapsed = self._elapsed + delta
    return self._elapsed < duration
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:finish()
    -- noop
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:draw()
    -- noop
end

--[[
rt.settings.battle.animations.consumable_applied = {
    duration = 2
}

--- @class bt.Animation.CONSUMABLE_APPLIED
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", rt.QueueableAnimation, function(target, consumable)
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _target = target,
        _consumable = consumable,

        _target_snapshot = {}, -- rt.Snapshot
        _label = {},          -- rt.Label
        _aspect = {},         -- rt.AspectLayout

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    self._label = rt.Label("<o><b>" .. self._consumable:get_name() .. "</o></b>")
    self._label:realize()
    self._label:set_justify_mode(rt.JustifyMode.CENTER)

    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    local sprite = rt.Sprite(sprite_id)
    sprite:realize()
    sprite:set_animation(sprite_index)

    local res_x, res_y = sprite:get_resolution()
    self._aspect = rt.AspectLayout(res_x / res_y, sprite)
    self._aspect:realize()

    local bounds = self._target:get_bounds()
    self._aspect:fit_into(bounds)

    self._target_snapshot = rt.Snapshot()
    self._target_snapshot:realize()
    self._target_snapshot:fit_into(bounds)

    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    self._target_snapshot:set_mix_color(rt.Palette.FOREGROUND)
    self._target_snapshot:set_mix_weight(0)

    local label_w = self._label:measure() * 0.5
    local start_x, start_y = bounds.width * 0.5, bounds.height * 0.15
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({start_x, start_y, finish_x, finish_y})

    local offset = 0.05
    self._target_path = rt.Spline({
        0, 0,
        -1 * offset, 0,
        offset, 0,
        0, 0
    })

end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:update(delta)
    local duration = rt.settings.battle.animations.consumable_applied.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- label animation
    local label_w, label_h = self._label:get_size()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))

    local bounds = self._target:get_bounds()
    self._label:fit_into(
        bounds.x + 0.5 * (bounds.width - label_w),
        bounds.y + bounds.height - pos_y - 0.5 * label_h,
        bounds.width,
        200
    )

    if fraction > 0.9 then
        self._label:set_opacity(clamp((1 - fraction) / 0.1, 0, 1))
    end

    -- target animation
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(self._target)
    self._target:set_is_visible(false)

    local current = self._target_snapshot:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sinusoid_ease_in_out(fraction))
    offset_x = offset_x * current.width
    offset_y = offset_y * current.height

    self._target_snapshot:set_position_offset(offset_x, offset_y)
    self._target_snapshot:set_mix_weight(rt.symmetrical_linear(fraction, 0.5))

    -- sprite animation
    local fade_duration = 0.5
    local fade_peak = 0.75
    local opacity = function(x)
        local order = 2
        if x < fade_duration then
            return rt.butterworth_highpass(x / fade_duration, order) * fade_peak
        elseif x > 1 - fade_duration then
            return rt.butterworth_lowpass((1 - x) / fade_duration, order) * fade_peak
        else
            return fade_peak
        end
    end

    self._aspect:set_opacity(opacity(fraction))
    return self._elapsed < duration
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:draw()
    self._target_snapshot:draw()
    self._aspect:draw()
    self._label:draw()
end
]]--
