--- @class bt.Animation.CONSUMABLE_APPLIED
bt.Animation.CONSUMABLE_APPLIED = meta.new_type("CONSUMABLE_APPLIED", rt.Animation, function(scene, slot_i, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_number(slot_i)
    meta.assert_isa(entity, bt.Entity)
    return meta.new(bt.Animation.CONSUMABLE_APPLIED, {
        _scene = scene,
        _slot_i = slot_i,
        _entity = entity,
        _is_done = false
    })
end)

--- @override
function bt.Animation.CONSUMABLE_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)
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