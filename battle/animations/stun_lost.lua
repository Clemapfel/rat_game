--- @class bt.Animation.STUN_LOST
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_LOST = meta.new_type("STUN_LOST", rt.Animation, function(scene, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)

    return meta.new(bt.Animation.STUN_LOST, {
        _scene = scene,
        _entity = entity,
        _target = nil, -- bt.EntitySprite

        _message = message,
        _message_done = false
    })
end)

--- @overload
function bt.Animation.STUN_LOST:start()
    self._target = self._scene:get_sprite(self._entity)
    self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @overload
function bt.Animation.STUN_LOST:update(delta)
    return self._message_done
end

--- @overload
function bt.Animation.STUN_LOST:finish()
    self._target:set_is_stunned(false)
end