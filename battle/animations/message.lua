--- @class bt.Animation.MESSAGE
--- @param text_box rt.TextBox
--- @param msg String
bt.Animation.MESSAGE = meta.new_type("MESSAGE", rt.Animation, function(scene, message, _)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_string(msg)
    meta.assert_nil(_)
    return meta.new(bt.Animation.MESSAGE, {
        _scene = scene,
        _message = message,
        _message_id = nil
    })
end)

--- @override
function bt.Animation.MESSAGE:start()
    self._message_id = self._scene.send_message(self._message, function()
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
