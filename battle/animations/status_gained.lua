--- @class bt.Animation.STATUS_APPLIED
--- @param status bt.Status
--- @param sprite bt.EntitySprite
bt.Animation.STATUS_GAINED = meta.new_type("STATUS_GAINED", rt.Animation, function(scene, status, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.Status)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.STATUS_GAINED, {
        _scene = scene,
        _status = status,
        _target = sprite
    })
end)