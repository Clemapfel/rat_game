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
        _signal_handler = -1
    })
end)

--- @override
function bt.Animation.MESSAGE:start()
    self._text_box:show()
    self._text_box:append(self._message)
    self._signal_handler = self._text_box:signal_connect("scrolling_done", function()
        self._scrolling_done = true
    end)
end

--- @override
function bt.Animation.MESSAGE:update(delta)
    return ternary(self._scrolling_done, rt.AnimationResult.DISCONTINUE, rt.AnimationResult.CONTINUE)
end

--- @override
function bt.Animation.MESSAGE:finish()
    self._text_box:signal_disconnect("scrolling_done", self._signal_handler)
    self._text_box:clear()
    self._text_box:hide()
end
