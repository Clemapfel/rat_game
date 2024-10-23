--- @class bt.Animation
--- @param status bt.GlobalStatus
--- @param
bt.Animation.GLOBAL_STATUS_GAINED = meta.new_type("GLOBAL_STATUS_GAINED", rt.Animation, function(scene, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatus)
    return meta.new(bt.Animation.GLOBAL_STATUS_GAINED, {
        _scene = scene,
        _status = status
    })
end)