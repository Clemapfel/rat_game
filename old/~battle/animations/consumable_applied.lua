rt.settings.battle.animations.consumable_applied = {
    duration = 2
}

--- @class bt.Animation.CONSUMABLE_APPLIED
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", bt.Animation, function(scene, target, consumable)
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _scene = scene,
        _target = target,
        _consumable = consumable,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Label

        _spritesheet = {},    -- rt.SpriteAtlasEntry
        _sprite = {},         -- rt.Sprite

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    if not self._target:get_is_realized() then
        self._target:realize()
    end

    self._label = rt.Label("<o><b>" .. self._consumable:get_name() .. "</o></b>")
    self._label:realize()
    self._label_path = {}

    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_frame(sprite_index)

    self._target_snapshot = rt.SnapshotLayout()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.Palette.FOREGROUND)
    self._target_snapshot:set_mix_weight(0)

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
        0, 0,
        -1 * offset, 0,
        offset, 0
    })

    local target = self._target
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.consumable_applied.duration
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

    -- sprite animation
    local fade_duration = 0.5
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

    self._sprite:set_opacity(opacity(fraction))
    self._sprite:fit_into(self._target:get_bounds())
    return self._elapsed < duration
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:draw()
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._sprite:draw()
    self._label:draw()
end
