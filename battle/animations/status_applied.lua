--- @class bt.Animation.STATUS_APPLIED
bt.Animation.STATUS_APPLIED = meta.new_type("STATUS_APPLIED", rt.Animation, function(scene, status, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_isa(entity, bt.Entity)
    return meta.new(bt.Animation.STATUS_APPLIED, {
        _scene = scene,
        _status = status,
        _entity = entity,
        _target = nil,
        _is_done = false
    })
end)

--- @override
function bt.Animation.STATUS_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)
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