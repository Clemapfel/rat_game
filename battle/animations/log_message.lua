rt.settings.battle.animation.log_message = {
    hold_duration = 1, -- seconds
}

--- @class bt.Animation.LOG_MESSAGE
bt.Animation.LOG_MESSAGE = meta.new_type("LOG_MESSAGE", rt.QueueableAnimation, function(scene, target, message)
    return meta.new(bt.Animation.LOG_MESSAGE, {
        _scene = scene,
        _target = target,
        _message = message,

        _is_holding = false,
        _elapsed = 0, -- time spend holding
    })
end)

--- @override
function bt.Animation.LOG_MESSAGE:start()
    self._scene:show_log()
    self._scene:send_message(self._message)
end

--- @override
function bt.Animation.LOG_MESSAGE:update(delta)
    if self._scene:get_are_messages_done() then
        self._elapsed = self._elapsed + delta
        if self._elapsed >= rt.settings.battle.animation.log_message.hold_duration then
            return rt.QueueableAnimationResult.DISCONTINUE
        end
    end
    return rt.QueueableAnimationResult.CONTINUE
end

--- @override
function bt.Animation.LOG_MESSAGE:finish()
    self._scene:hide_log()
end

--- @override
function bt.Animation.LOG_MESSAGE:draw()
    -- noop
end