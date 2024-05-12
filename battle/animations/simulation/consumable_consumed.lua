rt.settings.battle.animations.consumable_consumed = {
    duration = 2
}

--- @class bt.Animation.CONSUMABLE_CONSUMED
bt.Animation.CONSUMABLE_CONSUMED = meta.new_type("CONSUMABLE_CONSUMED", rt.QueueableAnimation, function(target, consumable)
    return meta.new(bt.Animation.CONSUMABLE_CONSUMED, {
        _target = target,
        _consumable = consumable,

        _label = {}, -- rt.Label
        _aspect = {}, -- rt.AspectLayout

        _elapsed = 0,
        _label_path = {},   -- rt.Spline
        _target_path = {}   -- rt.Spline
    })
end)

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:start()
    self._label = rt.Label("<o>Consumed: <b>" .. self._consumable:get_name() .. "</o></b>")
    self._label:realize()
    self._label_path = {}

    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    local sprite = rt.Sprite(sprite_id)
    sprite:realize()
    sprite:set_animation(sprite_index)

    local res_x, res_y = sprite:get_resolution()
    self._aspect = rt.AspectLayout(res_x / res_y, sprite)
    self._aspect:realize()

    local bounds = self._target:get_bounds()
    self._aspect:fit_into(bounds)

    local label_w = select(1, self._label:measure()) * 0.5
    local start_x, start_y = bounds.width * 0.75, bounds.height * 0.5
    local finish_x, finish_y = bounds.width * 0.75, bounds.height * 0.75
    self._label_path = rt.Spline({
        start_x, start_y,
        finish_x, finish_y
    })
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:update(delta)
    local duration = rt.settings.battle.animations.consumable_applied.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

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

    local fade_duration = 0.1
    local fade_peak = 0.75
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

    self._aspect:set_opacity(opacity(fraction))
    local target_bounds = self._target:get_bounds()
    local sprite_h = select(2, self._aspect:get_child():measure())
    self._aspect:fit_into(
        bounds.x,
        bounds.y + rt.continuous_step(fraction, 4) * bounds.height - sprite_h,
        bounds.width, bounds.height
    )
    return self._elapsed < duration
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:draw()
    self._aspect:draw()
    self._label:draw()
end