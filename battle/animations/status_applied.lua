--- @class bt.Animation.STATUS_APPLIED
bt.Animation.STATUS_APPLIED = meta.new_type("STATUS_APPLIED", rt.Animation, function(scene, status, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end
    return meta.new(bt.Animation.STATUS_APPLIED, {
        _scene = scene,
        _status = status,
        _entity = entity,
        _target = nil,
        _status_done = false,

        _message = message,
        _message_done = false
    })
end)

--- @override
function bt.Animation.STATUS_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)
    self._target:activate_status(self._status, function()
        self._status_done = true
    end)

    self._scene:send_message(self._message, function()
        self._message_done = false
    end)
end

--- @override
function bt.Animation.STATUS_APPLIED:finish()
end

--- @override
function bt.Animation.STATUS_APPLIED:update(delta)
    return self._status_done and self._message_done
end

--- @override
function bt.Animation.STATUS_APPLIED:draw()
end