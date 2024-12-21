--- @class bt.Animation.MESSAGE
--- @param text_box rt.TextBox
--- @param msg String
bt.Animation.MESSAGE = meta.new_type("MESSAGE", rt.Animation, function(scene, msg, _)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_string(msg)
    meta.assert_nil(_)
    return meta.new(bt.Animation.MESSAGE, {
        _text_box = scene:get_text_box(),
        _message = msg,
        _scrolling_done = false,
        _signal_handler = -1,
        _is_done = false
    })
end)

--- @override
function bt.Animation.MESSAGE:start()
    self._text_box:append(self._message, function()
        dbg("done")
        self._is_done = true
    end)
end

--- @override
function bt.Animation.MESSAGE:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.MESSAGE:finish()
end
