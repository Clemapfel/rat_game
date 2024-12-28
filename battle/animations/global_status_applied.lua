--- @class bt.Animation.GLOBAL_STATUS_APPLIED
bt.Animation.GLOBAL_STATUS_APPLIED = meta.new_type("GLOBAL_STATUS_APPLIED", rt.Animation, function(scene, global_status, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    if message ~= nil then meta.assert_string(message) end
    return meta.new(bt.Animation.GLOBAL_STATUS_APPLIED, {
        _scene = scene,
        _status = global_status,
        _status_done = false,
        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:start()
    self._scene:activate_global_status(self._status, function()
        self._status_done = true
    end)
    
    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:update(delta)
    return self._status_done and self._message_done
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:draw()
    -- noop
end