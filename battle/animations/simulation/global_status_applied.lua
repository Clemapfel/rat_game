rt.settings.battle.animations.global_status_applied = {
    duration = 2
}

--- @class bt.Animation.GLOBAL_STATUS_APPLIED
bt.Animation.GLOBAL_STATUS_APPLIED = meta.new_type("GLOBAL_STATUS_APPLIED", rt.QueueableAnimation, function(target, status)
    return meta.new(bt.Animation.GLOBAL_STATUS_APPLIED, {
        _target = target,
        _status = status,

        _label = {},          -- rt.Label
        _shape = rt.Rectangle(0, 0, 1, 1),

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:start()
    self._label = rt.Label("<o>Applied: <b><mono>" .. self._status:get_name() .. "</mono></b></o>")
    self._label:set_justify_mode(rt.JustifyMode.CENTER)
    self._label:realize()
    self._label_path = {}

    local bounds = self._target:get_bounds()
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })

    self._shape:resize(bounds)
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:update(delta)
    local duration = rt.settings.battle.animations.global_status_applied.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- label animation

    local bounds = self._target:get_bounds()
    local label_w, label_h = self._label:get_size()
    local _, pos_y = self._label_path:at(rt.exponential_plateau(fraction * 0.9))

    self._label:fit_into(
        bounds.x,
        bounds.y + bounds.height - pos_y,
        bounds.width,
        200
    )

    local fade_out_target = 0.9
    if fraction > fade_out_target then
        local v = clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label:set_opacity(v)
    end

    -- sprite animation
    local fade_duration = 0.5
    local fade_peak = 0.25
    local function opacity(x)
        local order = 2
        if x < fade_duration then
            return rt.butterworth_highpass(x / fade_duration, order) * fade_peak
        elseif x > 1 - fade_duration then
            return rt.butterworth_lowpass((1 - x) / fade_duration, order) * fade_peak
        else
            return fade_peak
        end
    end
    self._shape:set_opacity(opacity(fraction))

    return self._elapsed < duration
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:finish()
    -- noop
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:draw()
    self._shape:draw()
    self._label:draw()
end