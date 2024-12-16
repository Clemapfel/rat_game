--- @class bt.Animation.STUN_LOST
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_LOST = meta.new_type("STUN_LOST", rt.Animation, function(scene, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)

    return meta.new(bt.Animation.STUN_LOST, {
        _scene = scene,
        _entity = entity,
        _target = nil, -- bt.EntitySprite
    })
end)

--- @overload
function bt.Animation.STUN_LOST:start()
    self._target = self._scene:get_sprite(self._entity)
end

--- @overload
function bt.Animation.STUN_LOST:update(delta)
end

--- @overload
function bt.Animation.STUN_LOST:finish()
    self._target:set_is_stunned(false)
end