--- @class bt.Animation.GLOBAL_STATUS_APPLIED
--- @param status
bt.Animation.GLOBAL_STATUS_APPLIED = meta.new_type("GLOBAL_STATUS_APPLIED", rt.Animation, function(scene, status)
    return meta.new(bt.Animation.GLOBAL_STATUS_APPLIED, {
        _scene = scene,
        _status = status,
    })
end)