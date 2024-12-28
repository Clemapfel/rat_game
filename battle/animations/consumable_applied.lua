--- @class bt.Animation.CONSUMABLE_APPLIED
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", rt.Animation, function(scene, slot_i, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_number(slot_i)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _scene = scene,
        _slot_i = slot_i,
        _entity = entity,
        _status_done = false,
        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)
    self._target:activate_consumable(self._slot_i, function()
        self._status_done = true
    end)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:update(delta)
    return self._status_done and self._message_done
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:draw()
end