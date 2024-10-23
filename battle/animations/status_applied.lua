--- @class bt.Animation.STATUS_APPLIED
--- @param scene bt.BattleScene
--- @param status bt.Status
--- @param sprite bt.EntitySprite
bt.Animation.STATUS_APPLIED = meta.new_type("STATUS_APPLIED", rt.Animation, function(scene, status, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.Status)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.STATUS_APPLIED, {
        _scene = scene,
        _status = status,
        _target = sprite
    })
end)