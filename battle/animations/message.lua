--- @class bt.Animation.MESSAGE
--- @param text_box rt.TextBox
--- @param msg String
bt.Animation.MESSAGE = meta.class("MESSAGE", rt.Animation)

function bt.Animation.MESSAGE(scene, message, _)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_string(message)
    meta.assert_nil(_)
    meta.install(self, {
        _scene = scene,
        _message = message,
        _message_id = nil,
        _is_done = false
    })
end

--- @override
function bt.Animation.MESSAGE:start()
    self._message_id = self._scene:send_message(self._message, function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.MESSAGE:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.MESSAGE:finish()
    self._scene:skip_message(self._message_id)
end
