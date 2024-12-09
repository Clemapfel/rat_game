rt.settings.battle.animations.quicksave = {
    flash_intensity = 0.65
}

--- @class bt.Animation.QUICKSAVE
bt.Animation.QUICKSAVE = meta.new_type("QUICKSAVE", rt.Animation, function(scene, target, snapshot)
    meta.assert_isa(target, bt.QuicksaveIndicator)
    meta.assert_isa(snapshot, rt.RenderTexture)
    local flash = rt.settings.battle.animations.quicksave.flash_intensity
    return meta.new(bt.Animation.QUICKSAVE, {
        _scene = scene,
        _target = target,
        _is_done = false,
        _is_visible = true,

        _snapshot = snapshot, -- rt.RenderTexture
        _snapshot_done = false,

        _flash_color = rt.RGBA(flash, flash, flash, 0),
        _flash_animation = rt.TimedAnimation(
            0.2,
            0, 1,
            rt.InterpolationFunctions.DERIVATIVE_OF_GAUSSIAN_EASE_OUT
        )
    })
end)

--- @override
function bt.Animation.QUICKSAVE:start()
    -- noop, delayed until white flash in update
end

--- @override
function bt.Animation.QUICKSAVE:finish()
    self._target:signal_disconnect("done", self._signal_id)
end

do
    local previous = 0
    --- @override
    function bt.Animation.QUICKSAVE:update(delta)
        self._flash_animation:update(delta)
        local value = self._flash_animation:get_value()
        self._flash_color.a = value

        if self._snapshot_done == false and (value - previous < 0) then -- trigger once inflection point is reached
            local bounds = self._scene:get_bounds()

            -- overlay mesh over entire screen
            self._target:set_screenshot(self._snapshot)
            self._target:set_is_expanded(true)
            self._target:skip()

            -- start animation
            self._target:set_is_expanded(false)
            self._signal_id = self._target:signal_connect("done", function()
                self._is_done = true
            end)
            self._snapshot_done = true
        end

        previous = value
        return self._flash_animation:get_is_done() and self._is_done
    end
end

--- @override
function bt.Animation.QUICKSAVE:draw()
    if self._is_visible ~= true then return end

    self._target:draw_mesh()
    love.graphics.setColor(rt.color_unpack(self._flash_color))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
end
