rt.settings.battle.animations.hp_lost = {
    duration = 1
}

--- @class bt.Animation.HP_LOST
bt.Animation.HP_LOST = meta.new_type("HP_LOST", bt.Animation, function(target, value)
    return meta.new(bt.Animation.HP_LOST, {
        _target = target,
        _value = value,

        _label = {},       -- rt.Label
        _label_snapshot = {},    -- rt.SnapshotLayout
        _overlay = {},      -- rt.OverlayLayout
        _target_snapshot = {},

        _elapsed = 0,

        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.HP_LOST:start()
    self._label = rt.Label("<o><b><mono><color=WHITE>-" .. self._value .. "</o></b></mono></color>")
    self._label_snapshot = rt.SnapshotLayout()
    self._overlay = rt.OverlayLayout()
    self._target_snapshot = rt.SnapshotLayout()

    self._label_snapshot:set_child(self._label)
    self._target_snapshot:set_mix_color(rt.Palette.RED)
    self._target_snapshot:set_mix_weight(0)

    self._overlay:push_overlay(self._target_snapshot)
    self._overlay:push_overlay(self._label_snapshot)

    local overlay = self._overlay
    overlay:realize()
    local bounds = self._target:get_bounds()
    overlay:fit_into(bounds)

    local label = self._label
    local label_w = label:get_width() * 0.5
    local start_x, start_y = bounds.x + bounds.width * 0.75, bounds.y + bounds.height * 0.25
    local vertices = {}
    do -- path of label, simulates object accelerating as it is falling
        local n = 10
        local factor = 10
        local f = function(x)
            return (x - 0.3)^2 * 2
        end
        for j = 1, n+10 do
            local x = j / n
            local y = f(x)
            table.insert(vertices, start_x + 2 * factor * x)
            table.insert(vertices, start_y + 10 * factor * y)
        end
    end
    self._label_path = rt.Spline(vertices)

    local left_x, left_y = bounds.x + bounds.width * 0.5 - label_w, bounds.y
    local right_x, right_y = bounds.x + bounds.width * 0.5 + label_w, bounds.y
    self._target_path = rt.Spline({
        0, 0,
        20, 0,
        50, 0,
        0, 0,
    })

    local target = self._target
    local snapshot = self._target_snapshot
    snapshot:snapshot(target)
    target:set_is_visible(false)
    snapshot:set_invert(true)
end

--- @override
function bt.Animation.HP_LOST:update(delta)
    local duration = rt.settings.battle.animations.hp_lost.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    -- label animation
    local label = self._label_snapshot
    local w, h = label:get_size()
    local cutoff = 0.4 -- hold at position 0 for 0.3 * duration, then simulate exponential fall
    local post_cutoff_acceleration = 1.5
    local label_fraction = ternary(fraction < cutoff, 0, rt.exponential_acceleration((fraction - cutoff) / (1 - cutoff) * post_cutoff_acceleration))
    local pos_x, pos_y = self._label_path:at(label_fraction)
    label:fit_into(pos_x - 0.5 * w, pos_y, w, h)

    local fade_out_target = 0.8
    if fraction > fade_out_target then
        local v = 1 - clamp((1 - fraction) / (1 - fade_out_target), 0, 1)
        self._label_snapshot:set_opacity_offset(-v)
    end

    -- target animation
    local speed = 6
    local target = self._target_snapshot
    local current = target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.linear(speed * fraction))
    current.x = current.x + offset_x
    current.y = current.y + offset_y
    target:set_position_offset(offset_x, offset_y)
    target:set_mix_color(rt.Palette.RED)
    target:set_mix_weight(rt.symmetrical_linear(speed * fraction, 0.6))

    if speed * fraction > 1 then
        target:set_invert(false)
    end

    return self._elapsed < duration
end

--- @override
function bt.Animation.HP_LOST:finish()
    self._target:set_is_visible(true)
    self._target_snapshot:set_invert(false)
end

--- @override
function bt.Animation.HP_LOST:draw()
    self._overlay:draw()
end