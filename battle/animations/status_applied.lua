--- @class bt.Animation.STATUS_APPLIED
bt.Animation.STATUS_APPLIED = meta.class("STATUS_APPLIED", rt.Animation)

--- @brief
function bt.Animation.STATUS_APPLIED:instantiate(scene, status, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end
    meta.install(self, {
        _scene = scene,
        _status = status,
        _entity = entity,
        _target = nil,
        _status_done = false,

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end

--- @override
function bt.Animation.STATUS_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)
    self._target:activate_status(self._status, function()
        self._status_done = true
    end)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.STATUS_APPLIED:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.STATUS_APPLIED:update(delta)
    return self._status_done and self._message_done
end

--- @override
function bt.Animation.STATUS_APPLIED:draw()
end