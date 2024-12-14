--- @class bt.Animation.STATUS_APPLIED
--- @param scene bt.BattleScene
--- @param status bt.StatusConfig
--- @param sprite bt.EntitySprite
bt.Animation.STATUS_APPLIED = meta.new_type("STATUS_APPLIED", rt.Animation, function(scene, status, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.STATUS_APPLIED, {
        _scene = scene,
        _status = status,
        _target = sprite,
        _is_done = false
    })
end)

--- @override
function bt.Animation.STATUS_APPLIED:start()
    self._target:activate_status(self._status, function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.STATUS_APPLIED:finish()
end

--- @override
function bt.Animation.STATUS_APPLIED:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.STATUS_APPLIED:draw()
end