--- @class bt.Animation.DUMMY
bt.Animation.DUMMY = meta.class("DUMMY", rt.Animation)

--- @brief
function bt.Animation.DUMMY:instantiate(scene)
    return meta.new(bt.Animation.DUMMY, {
        _scene = scene
    })
end

-- use to time UI behavior by append animation