--- @class bt.Animation.QUICKLOAD
bt.Animation.QUICKLOAD = meta.new_type("QUICKLOAD", rt.Animation, function(scene, target, message)
    meta.assert_isa(target, bt.QuicksaveIndicator)
    if message ~= nil then meta.assert_string(message) end

    return meta.new(bt.Animation.QUICKLOAD, {
        _scene = scene,
        _target = target,
        _is_done = false,
        _message = message,
        _message_done = false
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

    self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.QUICKLOAD:finish()
    self._target:signal_disconnect("done", self._signal_id)
end

--- @override
function bt.Animation.QUICKLOAD:update(delta)
    return self._is_done and self._message_done
end

--- @override
function bt.Animation.QUICKLOAD:draw()
    self._target:draw_mesh()
end
