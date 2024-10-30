--- @class bt.Animation.CONSUMABLE_APPLIED
--- @param scene bt.BattleScene
--- @param slot_i Unsigned
--- @param sprite bt.EntitySprite
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", rt.Animation, function(scene, slot_i, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_number(slot_i)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _scene = scene,
        _slot_i = slot_i,
        _target = sprite,
        _is_done = false
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    self._target:activate_consumable(self._slot_i, function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:finish()
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.CONSUMABLE_APPLIED:draw()
end