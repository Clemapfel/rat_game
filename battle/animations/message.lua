--- @class bt.Animation.MESSAGE
bt.Animation.MESSAGE = meta.new_type("MESSAGE", rt.Animation, function(text_box, message)
    meta.assert_isa(text_box, rt.TextBox)
    meta.assert_string(message)
    return meta.new(bt.Animation.MESSAGE, {
        _text_box = text_box,
        _message = message,
        _scrolling_done = false,
        _signal_handler = -1
    })
end)

--- @override
function bt.Animation.MESSAGE:start()
    self._text_box:present()
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
    self._text_box:close()
end
