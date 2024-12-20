--- @class bt.Animation.DUMMY
bt.Animation.DUMMY = meta.new_type("DUMMY", rt.Animation, function(scene)
    return meta.new(bt.Animation.DUMMY, {
        _scene = scene
    })
end)
-- use to time UI behavior by append animation