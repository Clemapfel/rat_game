rt.settings.battle.animation.message = {
    hold_duration = 2, -- seconds
}

--- @class bt.Animation.MESSAGE
bt.Animation.MESSAGE = meta.new_type("MESSAGE", rt.QueueableAnimation, function(scene, message)
    meta.assert_isa(scene, bt.Scene)
    meta.assert_string(message)
    return meta.new(bt.Animation.MESSAGE, {
        _scene = scene,
        _message = message,

        _is_holding = false,
        _elapsed = 0, -- time spend holding
    })
end)

--- @override
function bt.Animation.MESSAGE:start()
    self._scene:show_log()
    self._scene:send_message(self._message)
end

--- @override
function bt.Animation.MESSAGE:update(delta)
    if self._scene:get_are_messages_done() then
        self._elapsed = self._elapsed + delta
        if self._elapsed >= rt.settings.battle.animation.message.hold_duration then
            return rt.QueueableAnimationResult.DISCONTINUE
        end
    end
    return rt.QueueableAnimationResult.CONTINUE
end

--- @override
function bt.Animation.MESSAGE:finish()
    self._scene:hide_log()
end

--- @override
function bt.Animation.MESSAGE:draw()
    -- noop
end