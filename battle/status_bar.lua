rt.settings.battle.status_bar = {

}

--- @class bt.StatusBar
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, rt.Animation, function(entity)
    return meta.new(bt.StatusBar)
end)
