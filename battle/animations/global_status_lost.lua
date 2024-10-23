--- @class bt.Animation.GLOBAL_STATUS_LOST
bt.Animation.GLOBAL_STATUS_LOST = meta.new_type("GLOBAL_STATUS_LOST", rt.Animation, function(scene, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatus)
    return meta.new(bt.Animation, {
        _scene = scene,
        _status = status
    })

end)