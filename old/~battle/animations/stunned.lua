rt.settings.battle.animations.stunned = {
    duration = 0.5
}

--- @class bt.Animation.STUNNED
bt.Animation.STUNNED = meta.new_type("STUNNED", bt.Animation, function(scene, target)
    return meta.new(bt.Animation.STUNNED, {
        _scene = scene,
        _target = target,

        _target_snapshot = {}, -- rt.SnapshotLayout
        _label = {},          -- rt.Glyph

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
        _target_path = {}, -- rt.Spline
    })
end)

--- @override
function bt.Animation.STUNNED:start()
    if not self._target:get_is_realized() then
        self._target:realize()
    end

    self._label = rt.Label("<o><b>STUNNED</b></o>")
    self._label:realize()
    self._label_path = {}

    self._target_snapshot = rt.SnapshotLayout()
    self._target_snapshot:realize()
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
    local target_path = {
        0, 0,
    }
    for i = 1, 4 do
        for x in range(
            -1 * offset, 0,
            offset, 0
        ) do 
            table.insert(target_path, x)
        end
    end
    table.insert(target_path, 0)
    table.insert(target_path, 0)

    self._target_path = rt.Spline(target_path)

    local target = self._target
    self._target:set_is_visible(true)
    self._target_snapshot:snapshot(target)
    target:set_is_visible(false)
end

--- @override
function bt.Animation.STUNNED:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.stunned.duration
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

    -- target animation
    local target = self._target_snapshot
    local current = target:get_bounds()
    local offset_x, offset_y = self._target_path:at(rt.sigmoid(fraction))
    offset_x = offset_x * current.width
    offset_y = offset_y * current.height
    current.x = current.x + offset_x
    current.y = current.y + offset_y
    target:set_position_offset(offset_x, offset_y)

    return self._elapsed < duration
end

--- @override
function bt.Animation.STUNNED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.STUNNED:draw()
    love.graphics.setCanvas(nil)
    self._target_snapshot:draw()
    self._label:draw()
end
