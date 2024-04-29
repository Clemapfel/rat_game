rt.settings.battle.animations.global_status_lost = {
    duration = 2
}

--- @class bt.Animation.GLOBAL_STATUS_LOST
bt.Animation.GLOBAL_STATUS_LOST = meta.new_type("GLOBAL_STATUS_LOST", bt.Animation, function(scene, target, status)
    return meta.new(bt.Animation.GLOBAL_STATUS_LOST, {
        _scene = scene,
        _target = target,
        _status = status,

        _label = {},          -- rt.Label
        _shape = rt.Rectangle(0, 0, 1, 1),

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:start()
    self._label = rt.Label("<o>Global Lost: <b><mono>" .. self._status:get_name() .. "</mono></b></o>")
    self._label:realize()
    self._label_path = {}

    local label = self._label
    local label_w = label:get_width() * 0.5
    local bounds = self._target:get_bounds()
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })

    self._shape:resize(bounds)

    local offset = 0.05
end

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.global_status_lost.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

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
function bt.Animation.GLOBAL_STATUS_LOST:finish()
end

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:draw()
    self._shape:draw()
    self._label:draw()
end
