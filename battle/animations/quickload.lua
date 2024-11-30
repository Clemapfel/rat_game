--- @class bt.Animation.QUICKLOAD
bt.Animation.QUICKLOAD = meta.new_type("QUICKLOAD", rt.Animation, function(scene, target)
    meta.assert_isa(target, bt.QuicksaveIndicator)
    return meta.new(bt.Animation.QUICKLOAD, {
        _scene = scene,
        _target = target,
        _is_done = false
    })
end)

--- @override
function bt.Animation.QUICKLOAD:start()
    self._target:set_is_expanded(false)
    self._target:skip()

    self._target:set_is_expanded(true)
    self._signal_id = self._target:signal_connect("done", function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.QUICKLOAD:finish()
    self._target:signal_disconnect("done", self._signal_id)
end

--- @override
function bt.Animation.QUICKLOAD:update(delta)
    dbg(self._is_done)
    return self._is_done
end

--- @override
function bt.Animation.QUICKLOAD:draw()
    self._target:draw_mesh()
end
