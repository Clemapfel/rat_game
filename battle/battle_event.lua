--- @class bt.Event
bt.BattleEvent = meta.new_type("BattleEvent", function(config)
    return meta.new(bt.BattleEvent, {
        _config = config
    })
end)