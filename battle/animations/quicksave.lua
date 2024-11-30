--- @class bt.Animation.QUICKSAVE
bt.Animation.QUICKSAVE = meta.new_type("QUICKSAVE", rt.Animation, function(scene, target)
    meta.assert_isa(target, bt.QuicksaveIndicator)
    return meta.new(bt.Animation.QUICKSAVE, {
        _scene = scene,
        _target = target,
        _snapshot = nil, -- rt.RenderTexture
        _is_done = false
    })
end)

--- @override
function bt.Animation.QUICKSAVE:start()
    local bounds = self._scene:get_bounds()
    self._snapshot = rt.RenderTexture(bounds.width, bounds.height, 0)
    self._snapshot:bind()
    self._target:set_is_visible(false)
    love.graphics.clear(0, 0, 0, 0)
    self._scene:draw()
    self._target:set_is_visible(true)
    self._snapshot:unbind()

    -- overlay mesh over entire screen
    self._target:set_screenshot(self._snapshot)
    self._target:set_is_expanded(true)
    self._target:skip()

    -- start animation
    self._target:set_is_expanded(false)
    self._signal_id = self._target:signal_connect("done", function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.QUICKSAVE:finish()
    self._target:signal_disconnect("done", self._signal_id)
end

--- @override
function bt.Animation.QUICKSAVE:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.QUICKSAVE:draw()
    self._target:draw_mesh()
end
