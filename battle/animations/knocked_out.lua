rt.settings.battle.animations.knocked_out = {
    duration = 2
}

--- @class bt.Animation.KNOCKED_OUT
bt.Animation.KNOCKED_OUT = meta.new_type("KNOCKED_OUT", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.KNOCKED_OUT, {
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
function bt.Animation.KNOCKED_OUT:start()
    if not self._target:get_is_realized() then
        self._target:realize()
    end

    self._scene:send_message(self._scene:format_name(self._target:get_entity()) .. " was <b><color=LIGHT_RED_3>knocked out</color></b>")

    self._label = rt.Label("<o><b><color=LIGHT_RED_3>Knocked Out</color></b></o>")
    self._label:realize()
    self._label_path = {}

    self._target_snapshot = rt.SnapshotLayout()
    self._target_snapshot:realize()
    self._target_snapshot:set_mix_color(rt.settings.battle.priority_queue_element.knocked_out_base_color)
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
function bt.Animation.KNOCKED_OUT:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.knocked_out.duration
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
function bt.Animation.KNOCKED_OUT:finish()
    self._target:set_is_visible(true)
    self._scene:get_priority_queue():set_knocked_out(self._target:get_entity(), true)
end

--- @override
function bt.Animation.KNOCKED_OUT:draw()
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._label:draw()
end


--[[
--- @class bt.Animation.KNOCKED_OUT
bt.Animation.KNOCKED_OUT_SUSTAIN = meta.new_type("KNOCKED_OUT_SUSTAIN", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.KNOCKED_OUT_SUSTAIN, {
        _scene = scene,
        _target = target,

        _snapshot = {}, -- rt.SnapshotLayout
        _elapsed = 0,

        _target_path = {},
        _mix_path = {},
        _is_active = true
    })
end)

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:start()
    self._snapshot = rt.SnapshotLayout()
    self._snapshot:realize()
    self._snapshot:fit_into(self._target:get_bounds())
    self._snapshot:snapshot(self._target)

    local vertices = {0, 0}
    local n_shakes = 5
    for _ = 1, n_shakes do
        for p in range(-1, 0, 1, 0, 0, 0) do
            table.insert(vertices, p)
        end
    end
    self._target_path = rt.Spline(vertices)
    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:update(delta)
    self._elapsed = self._elapsed + delta

    local duration = rt.settings.battle.animations.knocked_out.sustain_cycle_duration
    local fraction = (self._elapsed % duration) / duration
    self._snapshot:snapshot(self._target)
    self._snapshot:set_position_offset(self._target_path:at(fraction))
    return true -- sic, needs to be `finish`ed manually
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.KNOCKED_OUT_SUSTAIN:draw()
    if self._is_started then
        self._snapshot:draw()
    end
end
]]--