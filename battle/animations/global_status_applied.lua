--- @class bt.Animation.GLOBAL_STATUS_APPLIED
--- @param scene bt.BattleScene
--- @param status bt.GlobalStatusConfig
--- @param sprite bt.EntitySprite
bt.Animation.GLOBAL_STATUS_APPLIED = meta.new_type("GLOBAL_STATUS_APPLIED", rt.Animation, function(scene, global_status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    return meta.new(bt.Animation.GLOBAL_STATUS_APPLIED, {
        _scene = scene,
        _status = global_status,
        _is_done = false
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:start()
    self._scene:activate_global_status(self._status, function()
        self._is_done = true
    end)
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:finish()
    -- noop
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:update(delta)
    return self._is_done
end

--- @override
function bt.Animation.GLOBAL_STATUS_APPLIED:draw()
    -- noop
end