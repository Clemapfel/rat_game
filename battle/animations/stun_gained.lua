--- @class bt.Animation.STUN_GAINED
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_GAINED = meta.new_type("STUN_GAINED", rt.Animation, function(scene, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EntitySprite)

    return meta.new(bt.Animation.STUN_GAINED, {
        _scene = scene,
        _target = sprite,
    })
end)

--- @overload
function bt.Animation.STUN_GAINED:start()
end

--- @overload
function bt.Animation.STUN_GAINED:update(delta)
end

--- @overload
function bt.Animation.STUN_GAINED:finish()
    self._target:set_is_stunned(true)
end