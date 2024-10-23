--- @class bt.Animation.CONSUMABLE_GAINED
--- @param scene bt.BattleScene
--- @param consumable bt.Consumable
--- @param sprite bt.EntitySprite
bt.Animation.CONSUMABLE_GAINED = meta.new_type("CONSUMABLE_GAINED", rt.Animation, function(scene, consumable, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(consumable, bt.Consumable)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.CONSUMABLE_GAINED, {
        _scene = scene,
        _consumable = consumable,
        _target = sprite
    })
end)