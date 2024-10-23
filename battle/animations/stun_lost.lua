--- @class bt.Animation.STUN_LOST
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_LOST = meta.new_type("STUN_LOST", rt.Animation, function(scene, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EntitySprite)

    return meta.new(bt.Animation.STUN_LOST, {
        _scene = scene,
        _target = sprite,
    })
end)

--- @overload
function bt.Animation.STUN_LOST:start()
end

--- @overload
function bt.Animation.STUN_LOST:update(delta)
end

--- @overload
function bt.Animation.STUN_LOST:finish()
    self._target:set_is_stunned(false)
end